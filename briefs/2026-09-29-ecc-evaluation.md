---
id: 2026-09-29-ecc-evaluation
title: Evaluate Everything Claude Code for swarm integration
owner: claude-code
status: open
repo: venulo
branch: swarm/2026-09-29-ecc-evaluation
created: 2026-09-29
priority: normal
budget: cheap
needs_approval: false
attempts: 0
---

## Context
"Everything Claude Code" (ECC) by Afaan Mustafa — winner of an Anthropic hackathon — is an open-source stack of specialized subagents, 100+ workflow skills, slash commands, memory hooks, and token-optimization config, compatible with Claude Code, Codex, Cursor, and OpenCode. It could upgrade our swarm's individual workers. Evaluate before we install anything.

## Task
Report-only brief. Locate the canonical ECC repo (Anthropic hackathon winner by Afaan Mustafa; if you cannot verify the canonical repo, mark this brief `needs-human` instead of guessing). Then:
1. Inventory: subagents, skills, slash commands, and especially memory hooks — flag every hook that executes shell commands automatically.
2. Compatibility: determine whether our runner's headless CLI invocations would load ECC skills/subagents (config paths, env vars, flags involved). Test with a no-op if possible without installing.
3. Token story: describe ECC's token-optimization mechanisms concretely; assess whether the "up to 60%" claim is plausible or marketing.
4. Protocol fit: identify any conflicts between ECC's conventions and our swarm protocol (brief lifecycle open → claimed → done, branches `swarm/<brief-id>`, never merge to main, never deploy/email/spend, token ledger).
5. Recommend an install plan: which components to enable, which to disable (especially auto-executing hooks), and in what order.

## Acceptance criteria
- [ ] Report written to `results/2026-09-29-ecc-evaluation.md` in the swarm repo with: full inventory, shell-executing hooks flagged individually, headless-compatibility verdict, token-claim assessment, protocol conflicts, and an ordered install plan.
- [ ] No configuration was changed and nothing was installed (evaluation only).

## Constraints
- Work ONLY on branch `swarm/2026-09-29-ecc-evaluation`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Read-only: do not modify Claude Code / Codex configuration, do not install ECC.
- If the canonical repo cannot be verified, mark `needs-human` and stop.
