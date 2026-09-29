---
id: 2026-09-29-example-add-health-endpoint
title: "EXAMPLE: Add a /health endpoint (do not run)"
owner: claude-code
status: open
repo: venulo
branch: swarm/2026-09-29-example-add-health-endpoint
created: 2026-09-29
priority: low
budget: cheap
needs_approval: true
attempts: 0
---

## Context
This is an example brief showing the format. It is gated by `needs_approval: true`,
so the runner will skip it until a human removes the flag.

## Task
Add a `GET /health` endpoint that returns `{"status":"ok"}`.

## Acceptance criteria
- [ ] `GET /health` returns 200 with `{"status":"ok"}`
- [ ] Covered by one test

## Constraints
- Work ONLY on branch `swarm/<brief-id>`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Keep the diff minimal — no drive-by refactors.
- If the task is ambiguous or blocked, stop and say so instead of guessing.
