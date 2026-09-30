---
id: 2026-09-29-fix-paid-signup-handoff
title: Fix the paid-signup handoff (G1, G3)
owner: claude-code
status: open
repo: venulo
branch: swarm/2026-09-29-fix-paid-signup-handoff
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 1
---

## Context
Audit gaps G1 + G3: a user who abandons Stripe checkout is stuck `pending` with no on-screen way forward (uploads fail with a 402), and paying customers land on the dashboard after checkout, skipping venue setup — so their first report runs on generic defaults. This is the money path; fix it first.

## Task
In the work repo at `$WORK_REPO`:
1. After successful Stripe checkout, route the user to venue setup (not the bare dashboard) before they can run their first report.
2. For users stuck in `pending` (abandoned checkout): show a clear "resume checkout" path in the UI instead of a dead end, and make sure uploads don't fail with a bare 402 — return an explanatory message pointing at checkout.
3. If the audit's description doesn't match the code you find, trust the code and note the discrepancy in your summary.

## Acceptance criteria
- [ ] A test user completing checkout lands on venue setup; completing setup unlocks the first report with their venue's profile (not generic defaults).
- [ ] A `pending` user sees a resume-checkout UI and uploading shows an explanatory message, not a bare 402.
- [ ] No regressions: existing passing tests still pass; new behavior covered by at least one test.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-fix-paid-signup-handoff`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money. Use Stripe test mode / Stripe CLI only — never live keys.
- Keep the diff minimal — no drive-by refactors.
- If the task is ambiguous or blocked, stop and mark `needs-human` instead of guessing.
