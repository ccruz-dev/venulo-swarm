---
id: 2026-09-29-report-calibration-backfill
title: Snapshot report calibration; allow history backfill for new locations (G5, G6)
owner: claude-code
status: done
repo: venulo
branch: swarm/2026-09-29-report-calibration-backfill
created: 2026-09-29
priority: normal
budget: standard
needs_approval: false
attempts: 1
---

## Context
Audit gaps G5 + G6: the report page rebuilds the calibration note from the *current* venue profile, so the web report and the PDF can disagree about the same report. Separately, the 28-day upload limit means a new customer can't load past months, leaving trend features empty — the worst possible first impression.

## Task
In the work repo at `$WORK_REPO`:
1. Snapshot the calibration inputs onto each report at generation time; render the calibration note (web and PDF) from the snapshot, never from the live venue profile.
2. Allow a history backfill window when a location is new (e.g. permit uploads older than 28 days for the first N days after location creation — pick a sensible window and document it).
3. If the audit's description doesn't match the code you find, trust the code and note the discrepancy in your summary.

## Acceptance criteria
- [ ] Changing a venue profile after report generation does not change that report's calibration note on web or PDF (verify with a test).
- [ ] A brand-new location can upload older-than-28-days data within the backfill window; the window length is documented in code or docs.
- [ ] Existing passing tests still pass.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-report-calibration-backfill`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money.
- Keep the diff minimal — no drive-by refactors. A small data migration is acceptable if needed for the snapshot; make it reversible.
- If the task is ambiguous or blocked, stop and mark `needs-human` instead of guessing.
