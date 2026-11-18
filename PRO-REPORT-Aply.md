# Professional Vulnerability Report — Aply / TeamFeed

> **Author:** Security Researcher
> **Date:** 2026-11-18
> **Target:** `aply.com`, `teamfeed.co`, `teamfeed-server.onrender.com`, `aply-server.onrender.com`
> **Disclosure type:** Responsible disclosure (no public bug-bounty program exists for this target)
> **Contact suggested:** `hello@aply.com`, `hello@teamfeed.com`, `membership@aply.com`
> **Keywords:** unauthenticated, Stripe, payment bypass, authorization, business logic, IDOR, Firebase, enumeration

---

## Table of Contents
1. [Report 1 — CRITICAL: Unauthenticated Stripe financial operations](#report-1)
2. [Report 2 — MEDIUM: Unauthenticated, unrate-limited AI proxy](#report-2)
3. [Report 3 — LOW: Firebase user enumeration](#report-3)
4. [Report 4 — LOW: Public invite/demo endpoints](#report-4)
5. [Additional code-level observations (unconfirmed)](#additional)
6. [Safe-harbor / handling notes](#handling)

---

<a name="report-1"></a>
## Report 1 — CRITICAL: Unauthenticated Stripe financial operations

**Title:** Unauthenticated `/api/stripe/*` actions authorize money operations using only an `applicationId`

| Field | Value |
|---|---|
| Severity | **Critical** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (**9.1**) |
| Asset | `https://teamfeed-server.onrender.com` |
| Auth required | **None** |
| Status | **Confirmed** (server processed request without authentication challenge) |

### Summary
Four Stripe-related endpoints on the TeamFeed backend perform financial/state
actions and require **no authentication**. Authorization is effectively
"know the `applicationId`". The official web client calls them with **no
`Authorization` header** at all.

Affected endpoints:
```
POST /api/stripe/accept-no-charge      {applicationId}
POST /api/stripe/charge-balance        {applicationId}
POST /api/stripe/refund-deposit        {applicationId, reason?}
POST /api/stripe/create-checkout-session {pipelineId, applicationData, returnUrl}
```

### Steps to Reproduce (NON-DESTRUCTIVE)
> Uses a **non-existent** UUID only. This proves the missing auth check without
> triggering any real charge/refund/accept.

```bash
Z=00000000-0000-0000-0000-000000000000
for ep in accept-no-charge charge-balance refund-deposit; do
  curl -i -sS -X POST -H 'Content-Type: application/json' \
    -d "{\"applicationId\":\"$Z\"}" \
    "https://teamfeed-server.onrender.com/api/stripe/$ep"
done
```

### Evidence
```
HTTP/2 404
content-type: application/json
{"error":"Application not found"}
```
- Response is **404 "Application not found"**, **not 401/403**.
- No `Authorization` header was sent.
- The handler executed lookup logic *before* any auth check → the only gate is
  the identifier value.
- `create-checkout-session` with a bogus pipeline returns `400 {"error":"Unsupported pipeline"}` (also no auth).

### Impact
A candidate/attacker who can determine an `applicationId` can, **without any
account**:
- **Refund** the `$99` deposit (`refund-deposit`) → direct revenue loss / fraud.
- **Force-charge** the `$400` balance (`charge-balance`) → unauthorized charges
  to students' cards.
- **Accept** an application with no charge (`accept-no-charge`) → bypass the
  "only pay for results" model.

This is a **broken function-level authorization** flaw with direct monetary
impact and large-scale abuse potential.

### Root-cause note (chains with predictable IDs)
The client IDs in the Aply app are derived deterministically:
```
Op = email => email.toLowerCase().replace(/[^a-z0-9]+/g,"_")
applicationId = `${Op(email)}_${pipelineId}`
```
TeamFeed's application list reads the same Firestore `Applications` docs and
passes `doc.id`. This makes `applicationId` **derivable** from a candidate email
plus a public pipeline slug, materially raising exploitability.

### Recommended Fix
1. Require **authenticated, authorized** principal on every `/api/stripe/*`
   action (employer/admin, scoped to the pipeline).
2. Never authorize a money action by a body-supplied ID alone.
3. Use non-guessable IDs (no PII-derived doc IDs).
4. Add idempotency keys, server-side state machine, Stripe webhook
   reconciliation, audit logging, and per-user rate limits.

---

<a name="report-2"></a>
## Report 2 — MEDIUM: Unauthenticated, unrate-limited AI proxy

| Field | Value |
|---|---|
| Severity | **Medium** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L` (**5.3**) |
| Asset | `https://aply-server.onrender.com` |
| Status | **Confirmed** |

### Summary
Two LLM-backed endpoints are callable without authentication and show **no rate
limiting**. The client calls them directly from the browser.

```
POST /ai/enrich-company     {"name":"..."}      -> 200 {"ok":true,"bio":"..."}
POST /ai/evaluate-lane-fit  {"lane":"..."}      -> business-logic gate oracle
```

### Steps to Reproduce
```bash
for i in 1 2 3; do
  curl -sS -o /dev/null -w "%{http_code}\n" -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"probe $i\"}" \
    https://aply-server.onrender.com/ai/enrich-company
done
```
Three rapid responses: `200 200 200` (~2s each), no auth, no throttle.

### Impact
Open LLM proxy → **unbounded API-cost abuse / resource exhaustion**; the
lane-evaluation endpoint also exposes a business-logic decision oracle.
(Prompt-injection attempt against `enrich-company` was refused by the model;
no system-prompt leak was observed.)

### Recommended Fix
Authenticate callers, apply per-user/IP rate limits, cap token usage, validate
inputs, and monitor spend.

---

<a name="report-3"></a>
## Report 3 — LOW: Firebase user enumeration

| Field | Value |
|---|---|
| Severity | **Low** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` (**5.3**) |
| Asset | Firebase project `mrkt-2efde` (`identitytoolkit.googleapis.com`) |
| Status | **Confirmed** |

### Summary
Email-enumeration protection is disabled. Responses distinguish registered
emails from unregistered ones.

### Steps to Reproduce (random address only)
```bash
K=<FIREBASE_WEB_API_KEY>
curl -sS -H 'Content-Type: application/json' \
  -d '{"identifier":"zz-nonexistent@example.invalid","continueUri":"https://aply.com/"}' \
  "https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$K"
```
Evidence:
- `createAuthUri` → `{"registered": false, ...}`
- `sendOobCode` (PASSWORD_RESET) → `EMAIL_NOT_FOUND`
- `signInWithPassword` → `EMAIL_NOT_FOUND` vs `INVALID_PASSWORD`

### Impact
Allows account enumeration for phishing / credential-stuffing target lists.

### Recommended Fix
Enable Firebase **Email Enumeration Protection** (Identity Platform → Settings).

---

<a name="report-4"></a>
## Report 4 — LOW: Public invite/demo endpoints

| Field | Value |
|---|---|
| Severity | **Low / Informational** |
| Asset | `https://teamfeed-server.onrender.com` |
| Status | **Confirmed** |

### Summary
Endpoints return existence/validity to unauthenticated callers:
```
GET /api/invites/:token         -> {"kind":null,"valid":false,"status":"not_found"}
GET /api/collab/invites/:token  -> {"valid":false,"status":"not_found"}
GET /api/demo-shares/:id        -> {"error":"not_found"}
GET /api/company-categories     -> 200 (static list)
```
### Impact
Token-validity oracle (if tokens are guessable) and minor metadata exposure.
Low likelihood given random tokens; report as hardening.

### Recommended Fix
Rate-limit and/or authenticate; return uniform responses.

---

<a name="additional"></a>
## Additional code-level observations (NOT confirmed — need authenticated testing)

These are visible in the client bundle but were **not** validated (they depend
on Firestore security rules / an authenticated session). Listed for the
maintainer to verify — **do not treat as confirmed vulnerabilities**.

1. **Client writes paid/accepted state** — the Aply client calls
   `setDoc(doc(db,"Applications",id),{paymentStatus:"balance_paid",decisionStatus:"active"},{merge:true})`
   on join. If rules permit, a candidate self-activates paid/accepted status.
2. **Admin/role is client-controlled** — admin screen gated by hardcoded client
   allowlist `["nd@aply.com"]`; `role:"leadership"` / `isAdmin` written client-side.
3. **Predictable application IDs** (see Report 1 note) → possible IDOR/PII
   exposure depending on read rules.
4. **Client-side RBAC in TeamFeed feeds/teams** (`adminIds`/`memberIds`/
   `participants`) — self-elevation if rules trust these fields.
5. **Payment portal trust** — `?app=` (base64 JSON applicant data) and
   `?return=` (returnUrl) are forwarded unauthenticated to Stripe session
   creation; validate for open-redirect/data-forgery.

---

<a name="handling"></a>
## Safe-harbor / handling notes
- All testing above was **non-destructive**; the Stripe PoC uses a
  **non-existent** `applicationId` and performs **no** charge/refund/accept.
- No real user data was accessed, modified, or retained.
- This report is provided for **private responsible disclosure**. Please allow
  reasonable remediation time before any public discussion.
- No public bounty program was found for this target; this is goodwill
  disclosure, not a payout claim.

---

## Appendix A — Ably (separate, authorized program)
An authorized assessment of `ably.com` (VDP, `disclosure@ably.com`) was also
performed. **No confirmed vulnerabilities were found**; capability scoping,
token revocation, tenant isolation, SSRF protections, and realtime
authorization all behaved correctly. See `ably-assessment.txt`.

---
*End of report.*