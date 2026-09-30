#!/usr/bin/env bash
#
# venulo-swarm runner — polls the shared swarm repo for open briefs and
# executes them headlessly with Claude Code and/or Codex.
#
# Runs on YOUR machine (it drives your local agent CLIs).
#
# Things it will NEVER do (enforced by design, not just by prompting):
#   - merge anything into main (work lands on swarm/<brief-id> branches)
#   - deploy anything
#   - send email / spend money
#   - run briefs marked needs_approval: true
#   - retry a failed brief more than MAX_ATTEMPTS times
#
# Telemetry (feeds the JARVIS dashboard):
#   - status/tokens.jsonl   — one JSON object per agent run (token usage)
#   - status/dashboard.json — regenerated every pass: agents, briefs, tokens,
#                             XP. The dashboard fetches this single file.
#
set -euo pipefail

# ---------------- config (override via env) ----------------
SWARM_REPO="${SWARM_REPO:-$HOME/venulo-swarm}"  # the shared protocol repo
WORK_REPO="${WORK_REPO:-$HOME/venulo}"          # the app repo agents work in
POLL_INTERVAL="${POLL_INTERVAL:-300}"           # seconds between polls; 0 = single pass
ENABLED_AGENTS="${ENABLED_AGENTS:-claude-code,codex}"
CODEX_MODEL="${CODEX_MODEL:-}"                  # e.g. gpt-5-mini; empty = codex default
PYTHON_BIN="${PYTHON_BIN:-}"                  # python3 preferred; python fallback on Windows
ONLY_BRIEF="${ONLY_BRIEF:-}"                    # run just this brief id (dry runs); empty = all
MAX_ATTEMPTS=2
XP_PER_BRIEF=100

# Headless agents cannot answer permission prompts, so anything not granted
# here is silently denied. On 2026-09-29 that meant every code brief changed
# nothing: the agents were refused write access, said so, and exited 0.
# Edits are granted; the shell is limited to reading and running tests.
# Pushing, merging, deploying and network access stay denied by design.
# Comma-separated. The test patterns match how agents actually ran tests in the
# 2026-09-29 dry run (node tests/X.test.js, cd server && …, npm --prefix server …);
# the first version only allowed `npm test` and every test attempt was denied.
CLAUDE_ALLOWED_TOOLS="${CLAUDE_ALLOWED_TOOLS:-Read,Edit,Write,Glob,Grep,Bash(npm test:*),Bash(npm run test:*),Bash(npm run build:*),Bash(git status:*),Bash(git diff:*),Bash(git log:*),Bash(cd:*),Bash(ls:*),Bash(node tests/:*),Bash(node server/tests/:*),Bash(npm --prefix server run test:*),Bash(npm --prefix server test:*),Bash(npm --prefix client run build:*)}"
CLAUDE_DISALLOWED_TOOLS="${CLAUDE_DISALLOWED_TOOLS:-Bash(git push:*),Bash(git merge:*),Bash(railway:*),Bash(curl:*),Bash(npx prisma migrate deploy:*),WebFetch,WebSearch}"

# Appended to every brief. Exit code 0 only means the CLI did not crash; it says
# nothing about whether the work happened. The agent must say which it was.
STATUS_CONTRACT='

---
Runner contract: end your final message with exactly one of these lines:
SWARM_STATUS: done
SWARM_STATUS: needs-human: <one-line reason>
Use needs-human if you could not complete the task, were refused permission,
or stopped for a decision. Never claim done for work you did not do.'
# ------------------------------------------------------------

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
utcnow() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# frontmatter <file> <key> -> value (first match)
frontmatter() {
  awk -v k="$2" '
    /^---$/ { if (++n == 2) exit; next }
    n == 1 && $1 == k":" { sub(/^[^:]+:[ \t]*/, ""); print; exit }
  ' "$1"
}

# brief_body <file> -> markdown below the frontmatter
brief_body() {
  awk 'BEGIN{n=0} /^---$/{n++; next} n>=2' "$1"
}

heartbeat() { # <state> <detail>
  mkdir -p "$SWARM_REPO/status"
  cat > "$SWARM_REPO/status/runner.json" <<EOF
{
  "agent": "runner",
  "ts": "$(utcnow)",
  "state": "$1",
  "detail": "$2"
}
EOF
}

sync_swarm() {
  cd "$SWARM_REPO"
  git pull --rebase --quiet 2>/dev/null || git pull --quiet 2>/dev/null || true
}

push_swarm() { # <commit message>
  cd "$SWARM_REPO"
  # Only the paths the runner owns. `git add -A` swept up files another agent
  # had staged in this checkout on 2026-09-29 and pushed them under a runner
  # commit message. Humans and agents should still write from their own clone.
  git add -- briefs results status
  if ! git diff --cached --quiet; then
    git commit -q -m "$1" || return 0
    git push -q || log "WARN: push failed; will retry next loop"
  fi
}

claim_brief() { # <brief file>
  local f="$1" attempts
  attempts=$(frontmatter "$f" attempts); attempts=${attempts:-0}
  sed -i 's/^status: open$/status: claimed/' "$f"
  if grep -q '^attempts:' "$f"; then
    sed -i "s/^attempts: .*/attempts: $((attempts + 1))/" "$f"
  else
    sed -i "s/^status: claimed$/status: claimed\nattempts: $((attempts + 1))/" "$f"
  fi
}

set_status() { # <brief file> <status>
  sed -i "s/^status: .*/status: $2/" "$1"
}

# run_agent <owner> <brief id> <brief file> <workdir> <outdir>
# Runs the agent headlessly. For claude-code, captures --output-format json so
# token usage can be recorded. Writes agent-output.txt. Echoes rc on stdout.
run_agent() {
  local owner="$1" brief_id="$2" brief="$3" workdir="$4" outdir="$5"
  local budget prompt rc=0
  budget=$(frontmatter "$brief" budget); budget=${budget:-standard}
  prompt="$(brief_body "$brief")${STATUS_CONTRACT}"
  # --add-dir: report-only briefs must write results/<id>.md into the SWARM
  # repo, which is outside the work tree the agent runs in and so is otherwise
  # not writable. Scoped to results/ only.
  local perms=(--permission-mode acceptEdits
               --allowedTools "$CLAUDE_ALLOWED_TOOLS"
               --disallowedTools "$CLAUDE_DISALLOWED_TOOLS"
               --add-dir "$SWARM_REPO/results")
  # Codex exec defaults to a read-only sandbox, so a codex-owned brief could
  # neither edit code nor write its report. workspace-write keeps network off.
  local codex_perms=(--sandbox workspace-write --add-dir "$SWARM_REPO/results")
  (
    cd "$workdir"
    case "$owner" in
      claude-code)
        if [ "$budget" = "cheap" ]; then
          claude -p "$prompt" --model haiku "${perms[@]}" --output-format json > "$outdir/agent-raw.json" 2> "$outdir/agent-stderr.txt" || rc=$?
        else
          claude -p "$prompt" "${perms[@]}" --output-format json > "$outdir/agent-raw.json" 2> "$outdir/agent-stderr.txt" || rc=$?
        fi
        ;;
      codex)
        if [ -n "$CODEX_MODEL" ]; then
          codex exec --model "$CODEX_MODEL" "${codex_perms[@]}" "$prompt" > "$outdir/agent-output.txt" 2> "$outdir/agent-stderr.txt" || rc=$?
        else
          codex exec "${codex_perms[@]}" "$prompt" > "$outdir/agent-output.txt" 2> "$outdir/agent-stderr.txt" || rc=$?
        fi
        ;;
      *) log "unknown owner: $owner"; rc=1 ;;
    esac
    exit $rc
  ) || rc=$?
  echo "$rc"
}

# record_usage <owner> <brief id> <outdir> <rc>
# Parses agent output for token usage, appends to status/tokens.jsonl.
record_usage() {
  local owner="$1" brief_id="$2" outdir="$3" rc="$4"
  "$PYTHON_BIN" - "$owner" "$brief_id" "$outdir" "$rc" "$SWARM_REPO" <<'PYEOF'
import json, os, sys, datetime
owner, brief_id, outdir, rc, swarm = sys.argv[1:6]
entry = {
    "ts": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "brief": brief_id,
    "owner": owner,
    "exit": int(rc),
    "input_tokens": None,
    "output_tokens": None,
    "model": None,
}
if owner == "claude-code":
    try:
        raw = json.load(open(os.path.join(outdir, "agent-raw.json")))
        text = raw.get("result", "")
        with open(os.path.join(outdir, "agent-output.txt"), "w") as f:
            f.write(text if isinstance(text, str) else json.dumps(text))
        usage = raw.get("usage") or {}
        entry["input_tokens"] = usage.get("input_tokens")
        entry["output_tokens"] = usage.get("output_tokens")
        entry["model"] = raw.get("model")
    except Exception as e:
        entry["parse_error"] = str(e)[:200]
os.makedirs(os.path.join(swarm, "status"), exist_ok=True)
with open(os.path.join(swarm, "status", "tokens.jsonl"), "a") as f:
    f.write(json.dumps(entry) + "\n")
PYEOF
}

# write_dashboard <current_working_id> — regenerates status/dashboard.json
write_dashboard() {
  local working_id="${1:-}"
  "$PYTHON_BIN" - "$SWARM_REPO" "$working_id" "$XP_PER_BRIEF" <<'PYEOF'
import json, os, sys, datetime, glob, re
swarm, working_id, xp_per = sys.argv[1], sys.argv[2] or None, int(sys.argv[3])

def fm(path, key):
    in_fm, seen = False, 0
    with open(path) as f:
        for line in f:
            if line.strip() == "---":
                seen += 1
                in_fm = seen == 1
                if seen == 2:
                    break
                continue
            if in_fm and line.startswith(key + ":"):
                return line.split(":", 1)[1].strip().strip('"')
    return ""

briefs = []
for path in sorted(glob.glob(os.path.join(swarm, "briefs", "*.md"))):
    if path.endswith("_TEMPLATE.md"):
        continue
    bid = os.path.basename(path)[:-3]
    briefs.append({
        "id": bid,
        "title": fm(path, "title"),
        "owner": fm(path, "owner"),
        "status": fm(path, "status"),
        "budget": fm(path, "budget") or "standard",
        "priority": fm(path, "priority") or "normal",
    })

today = datetime.datetime.now(datetime.timezone.utc).date().isoformat()
tokens_today = {}
done_total = 0
for b in briefs:
    if b["status"] == "done":
        done_total += 1
tok_path = os.path.join(swarm, "status", "tokens.jsonl")
if os.path.exists(tok_path):
    with open(tok_path) as f:
        for line in f:
            try:
                e = json.loads(line)
            except Exception:
                continue
            if not e.get("ts", "").startswith(today):
                continue
            o = e.get("owner", "unknown")
            t = tokens_today.setdefault(o, {"input": 0, "output": 0, "runs": 0, "unknown": 0})
            t["runs"] += 1
            if isinstance(e.get("input_tokens"), int):
                t["input"] += e["input_tokens"]
                t["output"] += e.get("output_tokens") or 0
            else:
                t["unknown"] += 1

def agent_state(name):
    for b in briefs:
        if b["owner"] == name and b["status"] == "claimed":
            return {"state": "working", "current_brief": b["id"], "current_title": b["title"]}
    if working_id:
        wb = next((b for b in briefs if b["id"] == working_id), None)
        if wb and wb["owner"] == name:
            return {"state": "working", "current_brief": wb["id"], "current_title": wb["title"]}
    return {"state": "standby", "current_brief": None, "current_title": None}

snap = {
    "updated": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "agents": {
        "runner": {"state": "online"},
        "claude-code": agent_state("claude-code"),
        "codex": agent_state("codex"),
        "soup": {"state": "standby", "note": "reviewer job enriches this"},
    },
    "briefs": briefs,
    "tokens_today": tokens_today,
    "stats": {
        "done_total": done_total,
        "open": sum(1 for b in briefs if b["status"] == "open"),
        "claimed": sum(1 for b in briefs if b["status"] == "claimed"),
        "needs_human": sum(1 for b in briefs if b["status"] == "needs-human"),
        "xp": done_total * xp_per,
    },
}
os.makedirs(os.path.join(swarm, "status"), exist_ok=True)
with open(os.path.join(swarm, "status", "dashboard.json"), "w") as f:
    json.dump(snap, f, indent=2)
PYEOF
}

pass_once() {
  sync_swarm
  heartbeat "polling" "looking for open briefs"
  write_dashboard ""

  for brief in "$SWARM_REPO"/briefs/*.md; do
    [ -e "$brief" ] || continue
    case "$brief" in *_TEMPLATE.md) continue ;; esac
    # ONLY_BRIEF=<id>: restrict this run to one brief. Without it a single
    # pass claims every open brief, so a "dry run" is really the whole queue.
    if [ -n "${ONLY_BRIEF:-}" ] && [ "$(basename "$brief" .md)" != "$ONLY_BRIEF" ]; then
      continue
    fi

    local status owner approval
    status=$(frontmatter "$brief" status)
    [ "$status" = "open" ] || continue
    owner=$(frontmatter "$brief" owner)
    case ",$ENABLED_AGENTS," in *",$owner,"*) ;; *) continue ;; esac
    approval=$(frontmatter "$brief" needs_approval)
    if [ "$approval" = "true" ]; then
      log "skipping $(basename "$brief"): needs_approval=true"
      continue
    fi

    local id branch outdir
    id=$(basename "$brief" .md)
    branch="swarm/$id"
    outdir="$SWARM_REPO/results/$id"
    log "picked up brief: $id (owner=$owner)"

    claim_brief "$brief"
    push_swarm "runner: claim $id"

    # fresh branch off main in the work repo
    git -C "$WORK_REPO" fetch -q origin 2>/dev/null || true
    # Branch from origin/main, not local main. fetch never moves local main, so
    # a stale local main would put agents on old code — including code from
    # before a security fix was merged.
    if git -C "$WORK_REPO" show-ref --quiet refs/remotes/origin/main; then
      git -C "$WORK_REPO" checkout -q -B "$branch" origin/main
    elif git -C "$WORK_REPO" show-ref --quiet refs/heads/main; then
      git -C "$WORK_REPO" checkout -q -B "$branch" main
    else
      git -C "$WORK_REPO" checkout -q -B "$branch"
    fi

    heartbeat "working" "$id"
    write_dashboard "$id"
    mkdir -p "$outdir"

    rc=$(run_agent "$owner" "$id" "$brief" "$WORK_REPO" "$outdir")
    record_usage "$owner" "$id" "$outdir" "$rc"

    # commit whatever the agent did, push the branch (never main)
    local committed=0
    git -C "$WORK_REPO" add -A
    if ! git -C "$WORK_REPO" diff --cached --quiet; then
      git -C "$WORK_REPO" commit -q -m "swarm($id): agent work" && committed=1 || true
      git -C "$WORK_REPO" push -q -u origin "$branch" || log "WARN: branch push failed"
    fi
    git -C "$WORK_REPO" checkout -q main 2>/dev/null || true

    local attempts
    attempts=$(frontmatter "$brief" attempts); attempts=${attempts:-1}

    # What the agent SAYS happened: the last SWARM_STATUS line. A missing line
    # is treated as needs-human, not done — fail closed.
    local declared reason why=""
    # `|| true`: under set -euo pipefail a grep with no match would otherwise
    # abort the whole runner — in exactly the case this check exists for.
    declared=$(grep -E '^SWARM_STATUS:' "$outdir/agent-output.txt" 2>/dev/null | tail -1 | sed 's/^SWARM_STATUS:[[:space:]]*//' || true)
    reason=""
    case "$declared" in
      done) ;;
      needs-human*) why="${declared#needs-human}"; why="${why#:}"; why="${why# }"
                    reason="agent reported: ${why:-no reason given}" ;;
      "") reason="agent gave no SWARM_STATUS line" ;;
      *) reason="unrecognised SWARM_STATUS: $declared" ;;
    esac

    # What the evidence SAYS happened: commits on the branch, or the report file
    # a report-only brief is required to write. "done" needs both the agent's
    # word and the evidence.
    if [ -z "$reason" ] && [ "$committed" -eq 0 ] && [ ! -s "$SWARM_REPO/results/$id.md" ]; then
      reason="agent said done, but produced no commits and no results/$id.md"
    fi

    if [ "$rc" -eq 0 ] && [ -n "$reason" ]; then
      # Not a crash, so retrying will not help: permission refusals and
      # decisions need a person. Straight to needs-human, with the reason.
      printf '# Result: %s\n\n- finished: %s\n- exit: 0\n- status: needs-human\n- reason: %s\n\nSee agent-output.txt for what the agent found; it is often worth reading.\n' \
        "$id" "$(utcnow)" "$reason" > "$outdir/RESULT.md"
      set_status "$brief" "needs-human"
      write_dashboard ""
      push_swarm "runner: $id needs-human ($reason)"
      log "needs-human: $id — $reason"
    elif [ "$rc" -eq 0 ]; then
      cat > "$outdir/RESULT.md" <<EOF
# Result: $id
- brief: [$(basename "$brief")](../../briefs/$(basename "$brief"))
- owner: $owner
- branch: \`$branch\`
- finished: $(utcnow)
- exit: 0

## Summary
Agent completed without errors. Full log in agent-output.txt.
Review the branch diff before merging — the runner never merges to main.
EOF
      set_status "$brief" "done"
      write_dashboard ""
      push_swarm "runner: done $id"
      log "done: $id"
    elif [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
      printf '# Result: %s\n\nFailed %s times. Marked needs-human.\nSee agent-output.txt.\n' "$id" "$attempts" > "$outdir/RESULT.md"
      set_status "$brief" "needs-human"
      write_dashboard ""
      push_swarm "runner: $id needs-human after $attempts attempts"
      log "needs-human: $id"
    else
      set_status "$brief" "open" # back to open; retried next loop
      write_dashboard ""
      push_swarm "runner: $id attempt $attempts failed, will retry"
      log "will retry: $id"
    fi
  done

  heartbeat "polling" "idle"
  write_dashboard ""
  push_swarm "runner: heartbeat"
}

# ---------------- main ----------------
[ -d "$SWARM_REPO/.git" ] || { log "ERROR: swarm repo not found at $SWARM_REPO"; exit 1; }
git -C "$WORK_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "ERROR: work repo not found at $WORK_REPO"; exit 1; }
[ -z "$(git -C "$WORK_REPO" status --porcelain)" ] || { log "ERROR: work repo has uncommitted changes; refusing to start"; exit 1; }
command -v claude >/dev/null || log "WARN: 'claude' CLI not found on PATH"
command -v codex >/dev/null || log "WARN: 'codex' CLI not found on PATH"
if [ -z "$PYTHON_BIN" ]; then
  if command -v python3 >/dev/null; then
    PYTHON_BIN=python3
  elif command -v python >/dev/null; then
    PYTHON_BIN=python
  else
    log "ERROR: Python 3 required for telemetry"
    exit 1
  fi
fi
command -v "$PYTHON_BIN" >/dev/null || { log "ERROR: configured Python command not found: $PYTHON_BIN"; exit 1; }

log "swarm runner starting (poll every ${POLL_INTERVAL}s; agents: $ENABLED_AGENTS)"
if [ "$POLL_INTERVAL" -le 0 ]; then
  pass_once
else
  while true; do
    pass_once
    sleep "$POLL_INTERVAL"
  done
fi
