# Prior diagnosis (preserved)

Recovered from commit 8ffcbbd (2026-09-29 20:37). This run could not edit files, but
it mapped where upload error messages are lost. Kept here because the runner
overwrites agent-output.txt at the start of every run.

---

I couldn't make any changes: permission to write to `server/services/` was denied. So this is **`needs-human`**. Nothing has been edited, committed or tested. I'm not retrying the writes without your say-so; grant write access to the worktree and I'll apply the fix below and run the tests.

## What the code actually does

The audit is right, but it undercounts. The specific message gets lost in five places, not just the isolated parser, and the email bug is worse than described.

**Messages being dropped:**
1. **Isolated parser:** `server/services/parserIsolateChild.js:20` passes only the error `code` back to the main process. Then `safeParser.js:45` replaces it with "could not be safely parsed". This is the gap the audit describes.
2. **Worker check before parsing:** `uploadWorker.js:139-140` throws a plain `Error` without the user-facing message field (`userMessage`). The validator's "This file is missing a date column" is therefore replaced with the generic message at line 436. The audit doesn't mention this.
3. **Preview route:** `routes/uploads.js:141` returns the literal "CSV validation failed". The real messages go in a separate `validationErrors` field that the client never reads. This is the path most users hit, since they preview before confirming. Not in the audit.
4. **Client filter:** `client/src/utils/errorMessages.js:36` throws away any server message longer than 200 characters. Missing-column messages include the detected column list, so they usually go over that. Not in the audit.
5. The upload status page itself (`Upload.jsx:704`) shows the error unchanged, so once the server sends the right text it will display.

**Retry status and email:**
- `uploadWorker.js:436` sets the status to `failed` on every attempt, including the first of three.
- The email check at line 439, `!job.attemptsMade || job.attemptsMade >= 2`, is true on attempt 1 (because `attemptsMade` is 0) and again on attempt 3. So every job that fails for good sends **two** emails, not just sometimes.
- Invalid-file errors (like a missing Date column) are retried 3 times, taking about 2.5 minutes. With the status fix alone, users would wait that long before seeing the message.

## Planned fix (about 6 small edits)

1. **`parserIsolateChild.js`:** also send back `error.userMessage` when it's a string. Never send `error.message` or a stack trace.
2. **`safeParser.js`:** attach that text as `userMessage`, trimmed and limited to 500 characters.
3. **`uploadWorker.js`:**
   - Give the validation error its message: `e.userMessage = errorMsg`.
   - Work out once whether this attempt is the last one: it is if `attemptsMade + 1 >= opts.attempts`, or if the error has a `userMessage` (a bad file won't improve on retry).
   - If a retry is coming, set the status to `retrying` and rethrow.
   - If not, set the status to `failed` only when it isn't already: `updateMany({ where: { uploadId, status: { not: 'failed' } } })`. Send the email only if that update changed exactly one row. That guarantees at most one email even if a job is re-run, and the email will include the specific message (HTML-escaped).
   - For bad-file errors on the Redis-backed queue, throw BullMQ's `UnrecoverableError` so it doesn't retry.
   - Reuse the same last-attempt check in `finally` so the existing file-cleanup logic keeps working.
4. **`routes/uploads.js:264`:** add `'retrying'` to the in-progress statuses so a second upload can't be queued while a retry is pending. The client already keeps polling on any status it doesn't recognise.
5. **Client:** in `Upload.jsx` preview, show `validationErrors` when present, and raise the 200-character limit in `errorMessages.js` to 500. The stack-trace checks stay.
6. **Tests:**
   - Extend `parserIsolation.test.js`: parsing a real CSV with no Date column should produce a `userMessage` naming the Date column.
   - Extend `workerRecovery.test.js` with a stubbed `emailService` (no real email is sent). Attempt 1 fails → status is `retrying` and no email is sent. Final attempt fails → status is `failed` and one email is sent. Running it again → still one email.

To run the tests I'd also need to run `npm ci` in `server/`, because `node_modules` isn't installed in this worktree.