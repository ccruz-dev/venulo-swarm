---
id: 2026-09-29-venulo-repo-audit
title: Audit the Venulo app repo and propose the next build briefs
owner: claude-code
status: done
repo: venulo
branch: swarm/2026-09-29-venulo-repo-audit
created: 2026-09-29
priority: high
budget: standard
needs_approval: false
attempts: 1
---

## Context
Venulo is a revenue-intelligence platform for independent restaurants (Postgres, Prisma, Railway). The agent swarm is starting active development tonight. Before building features, we need a ground-truth map of what exists in the app repo.

## Task
Audit the work repo at `$WORK_REPO`. Do not modify any application code — this is a report-only brief.
1. Map the project structure: frameworks, entry points, database schema (Prisma), API routes, frontend pages.
2. For each major area, report its state: working, partially built, or stub/missing.
3. Document how to run the app locally (commands, env vars needed, seed data if any).
4. Trace the single most important user flow end to end — restaurant onboarding → POS data import → revenue-leak report — and report how complete it is, naming the exact gaps.

## Acceptance criteria
- [ ] Report written to `results/2026-09-29-venulo-repo-audit.md` in the swarm repo, covering: structure map, per-area status, local run instructions, and the end-to-end flow assessment with named gaps.
- [ ] Report ends with 5 concrete follow-up briefs ordered by leverage, each with a one-line task description and a suggested owner (claude-code or codex).
- [ ] No application code was modified.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-venulo-repo-audit`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Report-only: read code, don't change it.
- If `$WORK_REPO` is missing or unreadable, stop and mark the brief `needs-human` instead of guessing.
