# Venulo QA pass — blocked before runtime testing

Requested report date: 2026-09-29. Attempt performed: 2026-09-30.

**Status: needs-human. No end-to-end flow was verified.** Local PostgreSQL is unavailable; migration startup failed. Per the brief, testing stopped instead of inferring runtime results. This report is not pilot sign-off.

## Scope and evidence

- Worktree: `C:\Users\Cruzz\venulo-swarm-workrepo`.
- Branch: `swarm/2026-09-29-venulo-qa-pass`; HEAD: `4b057f4a11aa1fa3ac1eda0d1afacbf5a22f0aa7`.
- Read `results/2026-09-29-venulo-repo-audit/agent-raw.json`, including its `result` field. That field contains the audit summary; the fuller flow map/run notes are embedded in the same JSON's denied Write payload. Both were read. Prior static findings below are attributed to that audit, not presented as newly observed failures.
- Application code, tracked configuration, and lockfiles were not modified. No commits, merges, deployment, email, paid service calls, seed operations, or real-data submissions occurred.

## Severity-ordered observed blockers

### QA-ENV-01 — P0 local QA blocker: required PostgreSQL unavailable

**Classification:** Environment prerequisite failure, not a demonstrated product defect or production outage.

**Repro:**
1. In the required worktree, check `Get-Command psql,postgres,pg_ctl,docker -ErrorAction SilentlyContinue` and PostgreSQL/Docker services. Neither executable discovery nor service discovery returns a match. No PostgreSQL/Docker directory was found immediately under `C:\Program Files`.
2. Connect by TCP to `127.0.0.1:5432`; the result is `ECONNREFUSED`.
3. From `server`, set a process-local fake database URL, then run the installed Prisma CLI:

```powershell
$env:NODE_ENV='development'
$env:DATABASE_URL='postgresql://venulo_qa:fake_local_only@127.0.0.1:5432/venulo_qa?schema=public&connect_timeout=3'
$env:DIRECT_DATABASE_URL=$env:DATABASE_URL
$env:JWT_SECRET=('qa-local-only-' * 8)
$env:ENABLE_MARKETING_EMAILS='false'
$env:ENABLE_POS_INTEGRATIONS='false'
$env:RESEND_API_KEY=''
$env:STRIPE_SECRET_KEY=''
node node_modules/prisma/build/index.js migrate deploy
```

**Expected:** A disposable local PostgreSQL database accepts connections and the checked-in schema migrations apply, allowing the application to run against fake data.

**Actual:** Exit code 1. Prisma loads `prisma/schema.prisma`, identifies database `venulo_qa` at `127.0.0.1:5432`, then reports:

```text
Error: P1001: Can't reach database server at `127.0.0.1:5432`
Please make sure your database server is running at `127.0.0.1:5432`.
```

**Impact:** Signup, authenticated flows, upload jobs, reports, and settings cannot be meaningfully exercised. No application servers were started. A running frontend alone would not establish end-to-end correctness.

**Unblock:** Supply a reachable, disposable local PostgreSQL instance and local-only credentials, then rerun migrations and QA. No production or shared database should be substituted. No database installation or provisioning was attempted after confirming the blocker, following the explicit stop instruction.

## Audit G1–G6 verification queue

All entries below remain **not runtime verified**. Severity is provisional triage carried forward from the audit's described impact. Repro steps are future checks, not actions performed in this pass. G2's proposed lock contention remains a hypothesis.

| Priority | Gap and future repro | Expected | Audit-described actual |
|---|---|---|---|
| P0 | **G2: paid activation webhook.** With local Postgres and isolated fake Stripe responses, process checkout completion, inspect user/event writes, and inject a processing failure. Do not make paid calls. | Activation and idempotency state persist consistently; recoverable processing failures permit retry. | Audit suspects a transaction/global-client row-lock conflict; separately reports handler returning HTTP 200 on processing errors. Runtime contention and resulting state are unverified. |
| P1 | **G1: cancelled paid signup.** Create a fake pending signup, simulate checkout cancellation, follow the redirect, then attempt upload confirmation. | A clear resume-checkout action explains and resolves pending status. | Audit reports redirect to dashboard without pending guidance, followed by upload HTTP 402. Recovery through Billing reportedly exists. |
| P1 | **G3: venue setup skipped.** Simulate paid-checkout success and follow the dashboard wizard to upload. | Venue setup precedes the first analysis, or defaults are explicitly accepted. | Audit reports success returning to dashboard and wizard routing to upload, bypassing venue setup. |
| P1 | **G5: historical calibration changes.** Generate a fake report before venue setup, retain its PDF, change venue type, and reopen the same report. | Web and PDF retain the calibration actually used for that analysis. | Audit reports the web note reading the current profile while the PDF preserves the original calibration. |
| P1 | **G6: history backfill rejected.** Complete one fake monthly upload, then upload a different older month for the same location. | Distinct historical periods can populate trend features during onboarding. | Audit reports a 28-day cooldown based on report creation, preventing historical backfill. Confirm intended product policy when triaging. |
| P2 | **G4: non-actionable parser failure.** Submit a fake POS CSV missing a required Date column and inspect preview/worker feedback. | Feedback identifies the missing column and how to correct the export. | Audit reports specific parser text discarded across IPC and generic errors shown to the user. |

No new math, layout, dead-button, loading-state, or crash findings are claimed. The audit's additional G7–G11 risks (POS dedupe, retry status/email, large-file spread limits, HTTP report caching, and benchmark contamination) also remain unverified and should remain on the resumed QA agenda.

## Flows tested versus blocked or missing

| Flow | This pass | Existing audit context / remaining coverage |
|---|---|---|
| Local prerequisites and schema startup | Tested; blocked | Reproduced P1001 above. |
| Landing, demo, legal pages, public navigation | Not tested | Audit maps existing public routes; desktop/mobile layout and links remain unchecked. |
| Signup, login, password recovery, email verification, 2FA, Google OAuth | Not tested | Existing routes per audit. Email delivery must remain disabled; use local fixtures for token-dependent steps. |
| Restaurant onboarding, locations, venue profile | Not tested | Existing per audit; G1/G3 require verification. |
| CSV/XLSX preview, upload confirmation, processing and retry | Not tested | Existing per audit; G4/G6 and boundary files remain unchecked. |
| Direct POS connection/import | Not tested | Square/Clover partial and flag-gated per audit; Toast/Lightspeed direct sync reported absent. CSV import is distinct from direct sync. |
| Report generation, detail, PDF/XLSX, sharing, findings feedback | Not tested | Existing per audit; G5, totals, ownership, export agreement and share expiry remain unchecked. |
| Dashboard, notifications and spike alerts | Not tested | Existing per audit; empty/loading/error states and refreshed report visibility unchecked. |
| Analytics, operations, scorecards, employee detail, forecasts, compare, upsell playbook, menu economics | Not tested | Audit maps these features; plan gates and numerical agreement unchecked. |
| Settings, billing, help and changelog | Not tested | Existing per audit; persistence, validation and checkout recovery unchecked. |
| Team invitation/acceptance/login/portal and admin UI | Not tested | Separate auth surfaces per audit; no invitations or email sent. |
| SMS/WhatsApp daily summaries | Reported missing by prior audit | No runtime verification; audit says advertised Enterprise feature has no implementation. |
| Weekly digest, nurture and anonymous free report | Not tested; not classified as missing | Audit describes implemented, flag-gated flows. Marketing disabled for the attempted local setup. |

## Local run notes

- Node `v24.14.0`, npm `11.9.0`; audit documents Node 20 as the deployment pin. No compatibility conclusion can be drawn from this attempt.
- Both `server/node_modules` and `client/node_modules` exist; Express, Prisma client and dotenv resolve from the server directory. Unlike the earlier audit, dependency directories are present. Completeness was not established by an install or build.
- No `server/.env` or `client/.env` was found by the top-level `.env*` inventory; only `server/.env.example` was listed there. Root `.env.example` exists.
- Used process-local overrides rather than editing the examples: PostgreSQL URL and a development-only JWT value longer than 64 characters. Thus the known example-file defects were bypassed without changing tracked files.
- Local ports 5432, 3001 and 5173 all returned `ECONNREFUSED` before the migration attempt.
- Redis was not required for this prerequisite check; the audit documents an in-memory fallback.
- No tests, browser walkthrough, seed, fixture inserts, or application startup followed the failed migration. No fake restaurant data was submitted because the local database prerequisite never passed.
- `rg` is unavailable in this shell; PowerShell file/command discovery was used instead.
- Working-tree status was clean before testing. Final tracked/untracked status is checked after writing this report; the report is outside the application worktree.

## Definition of done per flow (all pending)

- [ ] **Local run:** Disposable local Postgres accepts migrations; server/client start; health checks succeed; external email, telemetry, paid AI and payments remain disabled or locally simulated.
- [ ] **Landing/public:** Navigation, signup CTAs, demo and legal links work; mobile and desktop layouts have no clipping or dead controls; invalid routes show a useful 404.
- [ ] **Auth/signup:** Fake accounts can register/login/logout; invalid inputs, duplicate accounts and locked sessions receive useful feedback; reset/verification/2FA use local fixtures without sending email.
- [ ] **Onboarding/locations:** Venue setup saves and reloads; pending checkout has a clear recovery path; paid and free paths both establish accurate venue context; ownership isolation holds.
- [ ] **Upload/import:** Valid fake CSV/XLSX previews match source rows and totals; invalid files produce actionable feedback; processing finishes with a report; retry states are truthful; historical periods can be handled according to explicit policy.
- [ ] **Direct POS:** Supported provider connection, cancellation, sync and dedupe work with local simulations; unavailable providers and disabled features are clearly identified.
- [ ] **Reports:** Known synthetic anomalies produce defensible amounts and periods; no double-counting; web/PDF/XLSX agree; calibration is historical; sharing, feedback and ownership work.
- [ ] **Dashboards/alerts:** New reports appear promptly; totals reconcile; empty/loading/error states work; alert thresholds and plan gates behave correctly without sending messages.
- [ ] **Advanced analysis:** Analytics, operations, scorecards, employees, forecasts, compare, upsell and menu economics show consistent data and units; insufficient history is explicit; access gates hold.
- [ ] **Settings/billing:** Edits validate and persist; security controls work; cancellation/pending/payment failures are recoverable using local simulations; no purchase occurs.
- [ ] **Team/admin:** Local invitation fixtures, separate sessions and role/location boundaries work; unauthorized access is denied; no real invitation is sent.
- [ ] **Help/changelog/notifications:** Links and actions work; read/unread state persists; empty/error states are usable.
- [ ] **Digest/free report/missing channels:** Feature flags are honored, anonymous abuse/error paths are handled, and advertised SMS/WhatsApp capabilities are implemented and locally verified or removed from promises.
