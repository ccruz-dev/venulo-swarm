# Local security tenant QA — blocked

Date: 2026-09-30. Branch: `swarm/2026-09-29-security-tenant-qa`.
Application commit: `4b057f4a11aa1fa3ac1eda0d1afacbf5a22f0aa7`.
Work repo: `C:\Users\Cruzz\venulo-swarm-workrepo`.

## Outcome

**NOT RUN. No security pass or failure verdict is established.** The local two-tenant application could not be provisioned with the available database prerequisites. Per the brief's instruction to document the blocker and stop, no HTTP attack probes, fake account creation, migrations, seed, or application startup were performed. No regression tests were added or executed. This report is a blocked-run record, not coverage of the deployed fixes.

## Blocker and evidence

- Read the specified audit JSON's `result` field: it identifies PostgreSQL as required, invalid SQLite example URLs, a JWT minimum of 64 characters, and destructive seed behavior.
- Current checkout has both client and server `node_modules`; Node resolves `express`, `@prisma/client`, and `dotenv` successfully. The earlier audit's missing-dependencies note no longer applies.
- `server/prisma/schema.prisma` declares PostgreSQL; `server/utils/validateEnv.js` requires a PostgreSQL URL and JWT secret of at least 64 characters. Only `.env.example` exists in `server`, not a local `.env`.
- `Get-Command node,npm,psql,postgres,pg_ctl,docker` finds Node/npm but no PostgreSQL tools or Docker on PATH. Standard `C:\Program Files\PostgreSQL` and `C:\Program Files\Docker` directories yielded no entries. Service discovery yielded no matching PostgreSQL/Docker service.
- Explicit TCP connections to **127.0.0.1:5432** and **127.0.0.1:5433** both returned **ECONNREFUSED**. No listener was discovered on the normal API/client ports 3001/5173 either.
- These checks establish that no usable local database was discovered, not that PostgreSQL cannot exist at an unknown custom path/port. No remote database configuration was used.

To resume: provide a disposable, isolated local PostgreSQL instance and its loopback-only connection details (or install local PostgreSQL). Use a fresh fake-data database, local JWT secret, and disable external email, payments, telemetry, AI, POS integrations, and marketing before booting. Do not use the destructive default seed against an existing database. Runtime route coverage and recovery timing still need execution.

## Planned probes and actual results

All rows below are **BLOCKED / NOT SENT**. Payloads are test specifications only; `A_LOCATION`, `B_LOCATION`, and `B_REPORT` represent future synthetic fixture IDs. There are no real account credentials or production IDs in this report. Severity is **unassessed**, because no vulnerability was reproduced.

| Probe / endpoint scope | Payload or sequence | Expected | Actual | Severity |
|---|---|---|---|---|
| Query injection: every analytics/report route listed below, plus sibling data routes | `?locationId[not]=A_LOCATION`; `?locationId[gt]=`; `?locationId[in][]=A_LOCATION&locationId[in][]=B_LOCATION`; `?locationId[notIn][]=A_LOCATION`; `?locationId[equals]=B_LOCATION`; `?locationId[]=B_LOCATION`; repeated `locationId=A_LOCATION&locationId=B_LOCATION` | 400 or scalar sanitization; never tenant B data | Not sent: no local database | Unassessed |
| Direct cross-tenant reads: analytics/report routes and sibling routes below | Authenticate as A; substitute B's location/report/upload/scorecard IDs into each supported path/query field; also run A-owned positive controls | 403/404 for foreign resources; no B markers in JSON, PDF, XLSX or CSV | Not sent: no fixtures or local database | Unassessed |
| Privilege escalation: registration, profile, removed upgrade route, billing, OAuth, team, admin and webhook families | Add `{"plan":"enterprise","role":"admin","onboardingPaid":true}` to otherwise valid input, including individual-field and nested variants; inspect stored fields before/after | Ignored or 403/404 and privileged state unchanged; distinguish permitted plan selection from paid entitlement | Not sent: no low-privilege fixture or local database | Unassessed |
| `POST /api/auth/login` | 11 rapid requests from one IP with a fake account email and wrong password; then correct password; capture status, response, Retry-After and recovery | Legitimate login works, or a documented lockout with verified recovery | Not sent: no fake accounts or local database | Unassessed |

## Sibling coverage exclusions

**All siblings are explicitly out of scope for execution in this blocked run**, solely because the brief requires stopping when the local app cannot run. The inventory below records discovered router declarations, not successful tests or a complete data-flow review.

- Query/ownership siblings: analytics, reports (including compare, metrics, exports, shared reports, AI/ask/explain), operations, employees, forecasts, scorecards, drilldown, menu economics, locations, uploads, venue profiles, goals, notes, notifications, POS and team portal. Each requires local fixtures and an authenticated positive control to avoid counting an unrelated gate as injection protection. Capability-based shared-report access needs valid, invalid and revoked token controls rather than assuming every shared link is owner-only.
- Privileged-write siblings: auth registration/profile/cancellation and OAuth callback; Stripe checkout/quantity and signed webhook handling; team invite/accept/revoke; admin routes and inline internal-key endpoints. The removed self-upgrade endpoint still needs a negative regression probe; its historical URL was not established during this blocked preflight. Exhaustive request-to-privileged-field tracing remains unperformed.
- External email, real Stripe checkout/payment, real OAuth/POS providers and paid AI calls are excluded independently by the no-email/no-money/local-only constraints. Any later coverage must use locally isolated fixtures without outbound calls.
- No endpoint is marked safe based on code inspection alone. No live production checks were performed.

## Router inventory for follow-up

Declarations below are from `server/routes/*.js`; mount prefixes are defined in `server/index.js`. `businessNotes` mounts at `/api/notes`, `posIntegrations` at `/api/pos`, `emailRoutes` at `/api/email`, `venueProfile` at `/api/venue-profile`, `menuEconomics` at `/api/menu-economics`, `freeReport` at `/api/free-report`, and `webhooks` at `/api/webhooks/stripe`. Other listed filenames generally match their `/api/<name>` mount. Admin and inline routes require additional inventory on resumption. Every declaration below is **NOT PROBED — local database unavailable**.

```text
analytics.js:15: router.get('/revenue', authenticate, async (req, res) => {
auth.js:217: router.post('/register', validateRegister, validate, async (req, res) => {
auth.js:324: router.post('/login', validateLogin, validate, async (req, res) => {
auth.js:428: router.post('/refresh', async (req, res) => {
auth.js:475: router.get('/me', authenticate, async (req, res) => {
auth.js:491: router.post('/logout', authenticate, async (req, res) => {
auth.js:510: router.put('/profile', authenticate, validateProfileUpdate, validate, async (req, res) => {
auth.js:590: router.post('/2fa/setup', authenticate, async (req, res) => {
auth.js:619: router.post('/2fa/verify', authenticate, async (req, res) => {
auth.js:664: router.post('/2fa/disable', authenticate, async (req, res) => {
auth.js:690: router.delete('/account', authenticate, async (req, res) => {
auth.js:698: router.get('/export-data', authenticate, async (req, res) => {
auth.js:740: router.delete('/delete-account', authenticate, async (req, res) => {
auth.js:787: router.get('/audit-log', authenticate, async (req, res) => {
auth.js:804: router.post('/forgot-password', forgotPasswordLimiter, validateForgotPassword, validate, async (req, res) => {
auth.js:830: router.post('/reset-password', validateResetPassword, validate, async (req, res) => {
auth.js:897: router.get('/verify-email', async (req, res) => {
auth.js:926: router.post('/resend-verification', authenticate, async (req, res) => {
auth.js:952: router.post('/email/change-request', authenticate, async (req, res) => {
auth.js:1009: router.get('/email/change-confirm', async (req, res) => {
auth.js:1064: router.post('/cancel-subscription', authenticate, async (req, res) => {
auth.js:1089: router.post('/google/2fa', body('code').isString().matches(/^[a-z0-9]{6,32}$/i), validate, async (req, res) => {
auth.js:1112: router.get('/google/config', (req, res) => {
auth.js:1117: router.get('/google', (req, res) => {
auth.js:1128: router.get('/google/callback', async (req, res) => {
businessNotes.js:48: router.get('/', verifyLocationOwnership, async (req, res) => {
businessNotes.js:62: router.post('/', userReportLimit, verifyLocationOwnership, async (req, res) => {
businessNotes.js:77: router.put('/:id', userReportLimit, async (req, res) => {
businessNotes.js:97: router.delete('/:id', async (req, res) => {
drilldown.js:26: router.get('/:uploadId/:algorithmId', async (req, res) => {
drilldown.js:102: router.get('/:uploadId/:algorithmId/export', async (req, res) => {
emailRoutes.js:20: router.get('/unsubscribe/:token', async (req, res) => {
employees.js:12: router.get('/insights', async (req, res) => {
forecasts.js:36: router.get('/latest', authenticate, requirePlan('enterprise'), async (req, res) => {
forecasts.js:72: router.get('/history', authenticate, requirePlan('enterprise'), async (req, res) => {
freeReport.js:55: router.post('/', rateLimitFree, upload.single('file'), async (req, res) => {
freeReport.js:137: router.post('/email', express.json({ limit: '50kb' }), async (req, res) => {
goals.js:10: router.get('/', async (req, res) => {
goals.js:25: router.put('/', async (req, res) => {
goals.js:65: router.delete('/:id', async (req, res) => {
goals.js:81: router.get('/progress', async (req, res) => {
legal.js:17: router.get('/privacy-policy', (req, res) => {
legal.js:26: router.post('/consent', authenticate, async (req, res) => {
legal.js:43: router.get('/tos-version', (req, res) => {
legal.js:52: router.post('/tos-acceptance', authenticate, async (req, res) => {
legal.js:69: router.get('/ccpa/do-not-sell', async (req, res) => {
legal.js:92: router.post('/ccpa/do-not-sell', authenticate, async (req, res) => {
legal.js:107: router.get('/cookies', (req, res) => {
legal.js:146: router.post('/request-deletion', authenticate, async (req, res) => {
locations.js:34: router.get('/', async (req, res) => {
locations.js:85: router.post('/', validateLocation, validate, async (req, res) => {
locations.js:101: router.put('/:id', verifyLocationOwnership, async (req, res) => {
locations.js:130: router.delete('/:id', verifyLocationOwnership, async (req, res) => {
menuEconomics.js:51: router.get('/contribution', async (req, res) => {
menuEconomics.js:106: router.get('/costs', verifyLocationOwnership, async (req, res) => {
menuEconomics.js:121: router.put('/costs', userReportLimit, verifyLocationOwnership,
menuEconomics.js:197: router.post('/promotion/compute', (req, res) => {
menuEconomics.js:224: router.get('/scenarios', verifyLocationOwnership, async (req, res) => {
menuEconomics.js:237: router.post('/scenarios', userReportLimit, verifyLocationOwnership, async (req, res) => {
menuEconomics.js:254: router.put('/scenarios/:id', userReportLimit, async (req, res) => {
menuEconomics.js:271: router.delete('/scenarios/:id', async (req, res) => {
notifications.js:17: router.get('/settings', async (req, res) => {
notifications.js:30: router.put('/settings', requirePlan('pro'), async (req, res) => {
notifications.js:48: router.get('/log', async (req, res) => {
notifications.js:62: router.post('/test-email', requirePlan('pro'), async (req, res) => {
operations.js:15: router.get('/', async (req, res) => {
posIntegrations.js:34: router.get('/status', authenticate, async (req, res) => {
posIntegrations.js:78: router.get('/connect/:provider', authenticate, async (req, res) => {
posIntegrations.js:135: router.get('/callback/:provider', async (req, res) => {
posIntegrations.js:201: router.post('/disconnect/:connectionId', authenticate, async (req, res) => {
posIntegrations.js:231: router.post('/sync/:connectionId', authenticate, async (req, res) => {
posIntegrations.js:255: router.patch('/:connectionId/toggle-sync', authenticate, async (req, res) => {
posIntegrations.js:283: router.get('/locations/:provider/:connectionId', authenticate, async (req, res) => {
posIntegrations.js:311: router.patch('/:connectionId/location', authenticate, async (req, res) => {
reports.js:49: router.get('/shared/:token', async (req, res) => {
reports.js:99: router.post('/:id/share', requirePlan('pro'), userShareTokenLimit, verifyReportOwnership, async (req, res) => {
reports.js:136: router.delete('/share/:token', async (req, res) => {
reports.js:155: router.get('/:id/ai-insights', userAiInsightLimit, verifyReportOwnership, async (req, res) => {
reports.js:266: router.get('/', async (req, res) => {
reports.js:321: router.get('/compare/locations', requirePlan('pro'), async (req, res) => {
reports.js:478: router.get('/metrics', async (req, res) => {
reports.js:497: router.get('/metrics/comparison', async (req, res) => {
reports.js:525: router.get('/:id', verifyReportOwnership, async (req, res) => {
reports.js:720: router.patch('/:id/findings/:type/fixed', verifyReportOwnership, async (req, res) => {
reports.js:749: router.put('/:id/findings/:findingType/feedback', userReportLimit, verifyReportOwnership, async (req, res) => {
reports.js:809: router.get('/:id/findings/:findingType/explain', verifyReportOwnership, async (req, res) => {
reports.js:825: router.post('/:id/ask', verifyReportOwnership, async (req, res) => {
reports.js:852: router.get('/:id/xlsx', verifyReportOwnership, async (req, res) => {
reports.js:906: router.get('/:id/pdf', verifyReportOwnership, async (req, res) => {
reports.js:927: router.get('/meta/algorithm-catalog', async (req, res) => {
scorecards.js:45: router.get('/', async (req, res) => {
scorecards.js:118: router.get('/employee/:scorecardId', async (req, res) => {
scorecards.js:181: router.get('/summary', async (req, res) => {
stripe.js:16: router.get('/billing-config', authenticate, (req, res) => {
stripe.js:21: router.post('/create-checkout', authenticate, async (req, res) => {
stripe.js:51: router.post('/create-portal', authenticate, async (req, res) => {
stripe.js:70: router.post('/update-quantity', authenticate, async (req, res) => {
team.js:95: router.get('/members', authenticate, requirePlan('enterprise'), async (req, res) => {
team.js:126: router.post('/invite', authenticate, requirePlan('enterprise'), async (req, res) => {
team.js:199: router.post('/members/:id/revoke', authenticate, requirePlan('enterprise'), async (req, res) => {
team.js:223: router.post('/auth/accept', teamLoginLimiter, async (req, res) => {
team.js:259: router.post('/auth/login', teamLoginLimiter, async (req, res) => {
team.js:287: router.post('/auth/logout', (req, res) => {
team.js:297: router.get('/portal/me', authenticateTeamMember, async (req, res) => {
team.js:314: router.get('/portal/reports', authenticateTeamMember, async (req, res) => {
team.js:338: router.get('/portal/reports/:id', authenticateTeamMember, async (req, res) => {
team.js:359: router.get('/portal/reports/:id/pdf', authenticateTeamMember, async (req, res) => {
uploads.js:109: router.post('/preview', upload.single('file'), handleMulterError, async (req, res) => {
uploads.js:172: router.post('/confirm', requireActiveSubscription, userUploadLimit, upload.fields([{ name: 'file', maxCount: 1 }, { name: 'laborFile', maxCount: 1 }]), handleMulterError, async (req, res) => {
uploads.js:340: router.get('/:uploadId/status', async (req, res) => {
uploads.js:379: router.get('/', async (req, res) => {
venueProfile.js:24: router.get('/:locationId', verifyLocationOwnership, async (req, res) => {
venueProfile.js:50: router.post('/:locationId/copy-from', verifyLocationOwnership, async (req, res) => {
venueProfile.js:89: router.post('/:locationId', verifyLocationOwnership, async (req, res) => {
venueProfile.js:151: router.get('/meta/options', async (req, res) => {
webhooks.js:9: router.post('/', express.raw({ type: 'application/json' }), async (req, res) => {
```

## Integrity and acceptance

- Report written in the swarm repo results directory.
- Required application branch was already checked out; no branch switch, commit or merge was performed.
- Application working tree was clean at preflight. No application code or configuration was changed. Only this report was written.
- No production URL was requested; the only network checks were two loopback TCP connections. No application, seed, migration, deployment, email, or payment operation ran.
- Two-tenant runtime testing, per-request observations, vulnerability severity assessment, and exhaustive sibling verification remain incomplete. Runner status: **needs-human** for local PostgreSQL availability.
