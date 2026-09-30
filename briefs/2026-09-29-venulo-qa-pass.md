---
id: 2026-09-29-venulo-qa-pass
title: End-to-end QA pass on Venulo — find logic and UI bugs
owner: codex
status: claimed
repo: venulo
branch: swarm/2026-09-29-venulo-qa-pass
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 1
---

## Context
Venulo is a revenue-intelligence platform for independent restaurants (Postgres, Prisma, Railway). Before pilots see it, we need a ruthless end-to-end QA pass: broken flows, wrong logic, and UI flaws, severity-ordered so builders know what to fix first.

## Task
Report-only brief — do not modify application code. Use fake restaurant data everywhere; never submit real data.
1. If `results/2026-09-29-venulo-repo-audit.md` exists in the swarm repo, read it first and use its run instructions and flow map. If absent, derive how to run the app locally from the work repo's README / package.json / env examples yourself.
2. Get the app running locally from `$WORK_REPO`. If you cannot get it running with reasonable effort, document the exact blocker and stop.
3. Walk every user-facing flow that exists: landing page, restaurant onboarding/signup, POS data import or upload, revenue-leak report generation and viewing, dashboards/alerts, settings. Note which expected flows are missing entirely.
4. For each flow, record: logic issues (wrong math, impossible states, bad defaults), UI bugs (broken layout, dead buttons, missing loading/error feedback), and blockers (crashes, 500s, hangs).
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
