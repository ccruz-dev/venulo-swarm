---
id: 2026-09-29-security-tenant-qa
title: Tenant-isolation and auth-boundary QA probe (local app)
owner: codex
status: open
repo: venulo
branch: swarm/2026-09-29-security-tenant-qa
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 0
---

## Context
Production just deployed PR #4 fixing a self-upgrade-to-Enterprise endpoint and a cross-tenant revenue-data leak (query-operator injection via `locationId[not]`). The production probes verify the deployed behavior; this brief probes the same attack surface in the local app so the fixes (and any sibling bugs) are covered by tests, not just by the deploy.

## Task
Report-only brief — do not modify application code. Use fake data everywhere; never touch production.
1. Run the app locally from `$WORK_REPO` (see the audit findings in `results/2026-09-29-venulo-repo-audit/agent-raw.json`, field `result`, for run notes).
2. With two fake accounts (two tenants), probe:
   - Query-operator injection: request values that turn into query operators (`locationId[not]`, `[gt]`, `[in]`, etc.) on every analytics/report endpoint. Expected: 400 or sanitized, never another tenant's data.
   - Privilege escalation: every route that writes a privileged field (plan, role, onboardingPaid) from request input — attempt to set it as a low-privilege user. Expected: ignored or 403/404, field unchanged.
   - Cross-tenant reads: request another tenant's location/report IDs directly. Expected: 404 or 403, never data.
   - Auth rate limiting: 11 rapid failed logins from one IP, then a legitimate login. Expected: legitimate login still works (or a documented lockout with recovery — record which).
3. Record for each probe: endpoint, payload, expected vs actual, severity if broken.

## Acceptance criteria
- [ ] Report written to `results/2026-09-29-security-tenant-qa.md` in the swarm repo with every probe, its result, and severity for failures.
- [ ] Every sibling of the two fixed vulnerabilities is either probed or explicitly listed as out of scope with a reason.
- [ ] No application code was modified; nothing touched production.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-security-tenant-qa`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money. LOCAL APP ONLY — never run these probes against production.
- Report-only: read and run code, don't change it.
- If the app cannot be run locally, document the blocker and stop instead of guessing.
