---
id: 2026-09-29-fix-dev-setup-docs
title: Fix dev setup and docs (env examples, README, seed guard, benchmarks)
owner: claude-code
status: open
repo: venulo
branch: swarm/2026-09-29-fix-dev-setup-docs
created: 2026-09-29
priority: normal
budget: standard
needs_approval: false
attempts: 0
---

## Context
The audit found local setup broken as shipped and docs out of date — this blocks every future contributor (human or agent): both `.env.example` files use placeholder `DATABASE_URL` values; `server/.env.example` has a `JWT_SECRET` placeholder shorter than the 64+ characters the check requires; `npm run seed` deletes every user, location, and report before seeding (no guard against non-local databases); CLAUDE.md says React 18 and 20 database models (code has React 19 and 24 models); the README describes SMTP email and a Vercel frontend (code uses Resend and a single Railway service); and test accounts count toward peer benchmarks.

## Task
In the work repo at `$WORK_REPO`:
1. Fix both `.env.example` files: valid placeholder formats (a `DATABASE_URL` shaped like a real local Postgres URL, a `JWT_SECRET` placeholder of 64+ characters) with comments explaining what to fill in.
2. Guard `npm run seed`: refuse to run against a non-local database unless an explicit flag (e.g. `--force`) is passed.
3. Update CLAUDE.md (React 19, 24 models) and README (Resend, single Railway service, no Vercel frontend). Remove or correct anything else you find that's factually wrong — don't rewrite docs wholesale.
4. Exclude test accounts from peer benchmarks.
5. If the audit's description doesn't match the code you find, trust the code and note the discrepancy in your summary.

## Acceptance criteria
- [ ] Following the README + `.env.example` files gets the app running locally with no undocumented steps.
- [ ] `npm run seed` refuses a non-local `DATABASE_URL` without `--force` (verify with a test or manual run against a dummy URL).
- [ ] Test accounts are excluded from benchmark calculations (covered by a test or verified query).

## Constraints
- Work ONLY on branch `swarm/2026-09-29-fix-dev-setup-docs`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Keep the diff minimal — docs fixes only where factually wrong.
- If the task is ambiguous or blocked, stop and mark `needs-human` instead of guessing.
