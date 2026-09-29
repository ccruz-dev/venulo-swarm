# Venulo Swarm Protocol

The constitution for Campbell's multi-agent build loop. Muse (Soup), Claude Code,
and Codex coordinate through this repo. Humans approve; agents never merge, deploy,
email, or spend.

## Roles

| Agent | Owns |
|---|---|
| `soup` | Writes briefs, reviews results, files follow-ups. Never touches code directly. |
| `claude-code` | Executes code briefs headlessly on the laptop runner. |
| `codex` | Executes code briefs headlessly on the laptop runner. |
| `human` (Campbell) | Approves merges, deploys, emails, spending. Unsticks `needs-human` briefs. |

## Repo layout

```
venulo-swarm/
  PROTOCOL.md          # this file
  SETUP.md             # laptop setup steps
  SOUP-SIDE.md         # what Soup's scheduled job does
  briefs/
    _TEMPLATE.md       # copy this to create a brief
    YYYY-MM-DD-slug.md # one file per task
  status/
    runner.json        # laptop runner heartbeat (updated every poll)
    soup.json          # Soup's reviewer heartbeat
    tokens.jsonl       # per-run token ledger (one JSON object per line)
    dashboard.json     # aggregated snapshot for the JARVIS dashboard (see DATA-CONTRACT.md)
  results/
    <brief-id>/
      RESULT.md        # outcome summary + branch pointer
      agent-output.txt # full agent log
      REVIEW-soup.md   # Soup's review (written by reviewer job)
  scripts/
    runner.sh          # laptop poller — the only thing that invokes coding agents
    new-brief.sh       # helper: new-brief.sh <owner> "<title>" [budget]
```

## Brief lifecycle

```
open → claimed → done
  ↓        ↓
  needs-human (stuck, failed twice, or needs a decision)
```

- `open`: ready for pickup.
- `claimed`: runner picked it up. Prevents double-execution.
- `done`: result recorded in `results/<id>/`. Awaiting review/merge by human.
- `needs-human`: agent failed twice, output was confused, or the brief needs a
  decision only Campbell can make. The runner moves on; Soup surfaces it in the digest.

## Hard rules (enforced by the runner, not just by prompting)

1. The runner NEVER merges to `main`, deploys, sends email, or spends money.
   Code lands on branches named `swarm/<brief-id>`. Campbell merges via PR review.
2. Briefs with `needs_approval: true` are never picked up. Campbell flips the flag
   (or the status) when ready.
3. A brief that fails twice goes to `needs-human`. No infinite retry loops, no
   token bonfires.
4. No secrets in this repo. Ever. No API keys, tokens, passwords, customer data.
   The repo is public so Soup can pull it.
5. Briefs stay small and specific. One task, clear acceptance criteria, relevant
   file paths — not whole-repo dumps. (This is the prompt-caching strategy:
   small context in, small context out.)

## Cost routing

- `budget: cheap` → Haiku-class models (`claude -p --model haiku`), trivial tasks:
  refactors, docs, test additions, review summaries.
- `budget: standard` → default models, real feature work.
- Free-tier models (GitHub Models, Groq, etc.) are for Soup-side drafts and
  reviews only — never for unattended code changes.
- Overnight/heavy work goes through the runner on the laptop, not through
  metered chat.

## Brief ownership

- `owner: claude-code` / `owner: codex` — picked up by the laptop runner.
- `owner: soup` — picked up by Soup's scheduled reviewer job. Used for research,
  spec-writing, and review briefs. The runner ignores these.
