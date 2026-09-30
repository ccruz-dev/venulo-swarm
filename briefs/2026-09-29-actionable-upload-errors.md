---
id: 2026-09-29-actionable-upload-errors
title: Show actionable upload errors; fix premature job-failed state (G4)
owner: codex
status: needs-human
repo: venulo
branch: swarm/2026-09-29-actionable-upload-errors
created: 2026-09-29
priority: normal
budget: standard
needs_approval: false
attempts: 1
---

## Context
Audit gap G4: the isolated CSV parser drops specific error messages (e.g. "missing Date column"), so users only see "could not be processed". Related: a job shows "failed" while a retry is still pending, and the failure email can go out twice. Users can't self-serve past the most common failure.

## Task
Start from `results/2026-09-29-actionable-upload-errors/agent-output.txt` in the swarm repo: a previous run mapped all five drop points with file/line references. Do not re-derive them.

In the work repo at `$WORK_REPO`:
1. Propagate specific parser error messages to the UI (e.g. missing column names, bad date formats, empty file) instead of the generic "could not be processed". Keep messages user-friendly, not stack traces.
2. Only mark a job `failed` after its last retry is exhausted; while a retry is pending the status must reflect that.
3. Ensure the failure notification/email fires exactly once per failed job.
4. If the audit's description doesn't match the code you find, trust the code and note the discrepancy in your summary.

## Acceptance criteria
- [ ] Uploading a CSV missing the Date column shows a message naming the missing column (verify manually or with a test).
- [ ] A job with a retry pending does not display as failed; the failure email is sent at most once (covered by a test or verified in code path).
- [ ] Existing passing tests still pass.

## Constraints
- Work ONLY on branch `swarm/2026-09-29-actionable-upload-errors`. Never commit to or merge into `main`.
- Never deploy, send email, or spend money (do not send real emails while testing — stub or assert the send call).
- Keep the diff minimal — no drive-by refactors.
- If the task is ambiguous or blocked, stop and mark `needs-human` instead of guessing.
