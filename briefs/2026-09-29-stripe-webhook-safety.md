---
id: 2026-09-29-stripe-webhook-safety
title: Make the Stripe webhook safe (G2)
owner: claude-code
status: open
repo: venulo
branch: swarm/2026-09-29-stripe-webhook-safety
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 1
---

## Context
Audit gap G2: the Stripe webhook handler likely blocks itself on the user row (losing `onboardingPaid` and the duplicate-event record), and — confirmed from code — it returns 200 even when processing fails, so Stripe never retries. Silent payment-state corruption on the money path.

## Task
In the work repo at `$WORK_REPO`:
1. Eliminate the lock contention on the user row in the webhook handler (reorder operations, shorten the transaction, or use an idempotency/duplicate-event record written independently — pick the smallest correct fix).
2. Return a non-2xx status when event processing fails so Stripe retries; keep 200 only for genuinely handled events (including duplicates already recorded).
3. Ensure `onboardingPaid` cannot be silently lost: the duplicate-event record must be written atomically with (or before) the state change it guards.
4. If the audit's description doesn't match the code you find, trust the code and note the discrepancy in your summary.

## Acceptance criteria
- [ ] A failing webhook run returns non-2xx (verify with Stripe CLI `stripe listen` / test events, or a unit test simulating failure).
- [ ] Re-delivering the same event twice results in exactly one state change and one duplicate-event record.
- [ ] `onboardingPaid` is set correctly on the success path; existing passing tests still pass.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-stripe-webhook-safety`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money. Use Stripe test mode / Stripe CLI only — never live keys.
- Keep the diff minimal — no drive-by refactors.
- If the task is ambiguous or blocked, stop and mark `needs-human` instead of guessing.
