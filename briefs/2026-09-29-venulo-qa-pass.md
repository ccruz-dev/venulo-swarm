---
id: 2026-09-29-venulo-qa-pass
title: End-to-end QA pass on Venulo — find logic and UI bugs
owner: codex
status: open
repo: venulo
branch: swarm/2026-09-29-venulo-qa-pass
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 0
---

## Context
Venulo is a revenue-intelligence platform for independent restaurants (Postgres, Prisma, Railway). Before pilots see it, we need a ruthless end-to-end QA pass: broken flows, wrong logic, and UI flaws, severity-ordered so builders know what to fix first.

## Task
Report-only brief — do not modify application code. Use fake restaurant data everywhere; never submit real data.
1. Read the audit findings first: in the swarm repo, `results/2026-09-29-venulo-repo-audit/agent-raw.json`, field `result` — it contains the full audit (flow map, run notes, known gaps G1–G6). Use it; don't re-derive what the audit already documented.
2. Get the app running locally from `$WORK_REPO` (the audit notes the `.env.example` files are broken as shipped — expect to fix env values locally without committing those changes).
3. Walk every user-facing flow that exists: landing page, restaurant onboarding/signup, POS data import or upload, revenue-leak report generation and viewing, dashboards/alerts, settings. Note which expected flows are missing entirely.
4. For each flow, record: logic issues (wrong math, impossible states, bad defaults), UI bugs (broken layout, dead buttons, missing loading/error feedback), and blockers (crashes, 500s, hangs). Pay special attention to the audit's G1–G6 — verify each is real and find what the audit missed.
5. Produce a bug list ordered by severity — P0 (flow completely broken), P1 (wrong data or logic), P2 (UI/UX flaws). Every bug needs: repro steps, expected vs actual, severity.

## Acceptance criteria
- [ ] Bug report written to `results/2026-09-29-venulo-qa-pass.md` in the swarm repo, with severity-ordered bugs (each with repro steps, expected vs actual), a list of flows tested vs flows missing, and local run notes.
- [ ] Report ends with a short "definition of done" checklist per flow (what "working" means).
- [ ] No application code was modified.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-venulo-qa-pass`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Report-only: read and run code, don't change it. Use only fake data.
- If the app cannot be run locally, document the blocker precisely and stop instead of guessing.
