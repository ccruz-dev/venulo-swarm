# Setup (your laptop)

## 1. Create the GitHub repo

- New repo named `venulo-swarm`, **public** (the protocol forbids secrets in it,
  so public is safe — and it's how Soup pulls it).
- Copy the contents of this package into it and push.

## 2. Check the CLIs

```bash
claude --version   # Claude Code, authenticated
codex --version    # Codex CLI, authenticated
```

The runner calls `claude -p "<brief>"` and `codex exec "<brief>"` headlessly.
If either isn't installed/authed, the runner logs a warning and skips that
agent's briefs.

## 3. Configure the runner

```bash
chmod +x ~/venulo-swarm/scripts/*.sh
```

Defaults assume `~/venulo-swarm` and `~/venulo`. Override with env vars if your
paths differ:

```bash
export SWARM_REPO="$HOME/path/to/venulo-swarm"
export WORK_REPO="$HOME/path/to/venulo"
export POLL_INTERVAL=300   # seconds; 0 = single pass then exit
export ENABLED_AGENTS="claude-code,codex"
export CODEX_MODEL=""      # e.g. gpt-5-mini to route cheap; empty = default
```

## 4. Test with a single pass

```bash
POLL_INTERVAL=0 ~/venulo-swarm/scripts/runner.sh
```

It should pull, find nothing open (the example brief is `needs_approval: true`),
update `status/runner.json`, and exit.

## 5. Create your first real brief

```bash
~/venulo-swarm/scripts/new-brief.sh claude-code "Add health endpoint" cheap
# edit the brief, then:
cd ~/venulo-swarm && git add -A && git commit -m "brief: health endpoint" && git push
```

## 6. Keep the runner alive

Simplest: a tmux session.

```bash
tmux new -s swarm
~/venulo-swarm/scripts/runner.sh
# detach: Ctrl-b, d
```

Later: a launchd/systemd service if you want it surviving reboots.

## 7. Activate Soup's side

Send Soup the repo URL. I'll clone it, start the 6-hour reviewer job, and
you'll get digests of what's done, what's stuck, and what needs your approval.

## The loop, end to end

1. You (or Soup) write a brief → commit → push.
2. Runner polls, claims it, cuts branch `swarm/<id>` in `~/venulo`.
3. Claude Code/Codex runs headless on that branch; runner pushes the branch.
4. Runner records `results/<id>/`, marks brief `done`.
5. Soup reviews on schedule, writes `REVIEW-soup.md`, digests to you.
6. You review the PR/branch and merge. Nothing reaches `main` without you.
