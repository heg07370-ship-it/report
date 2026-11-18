# Bug Reports Index — Aply / TeamFeed

Target: `aply.com`, `teamfeed.co`, `teamfeed-server.onrender.com`, `aply-server.onrender.com`
Date: 2026-11-18 · Disclosure: responsible (no public program)
Keywords: unauthenticated, Stripe, payment, business logic, authorization, IDOR, Firebase, enumeration

## Confirmed

| ID | Severity | Title | File |
|----|----------|-------|------|
| BUG-01 | **Critical** | Unauthenticated Stripe financial operations (`applicationId`-keyed) | [BUG-01-unauth-stripe.md](BUG-01-unauth-stripe.md) |
| BUG-02 | **Medium** | Unauthenticated, unrate-limited AI proxy | [BUG-02-unauth-ai-proxy.md](BUG-02-unauth-ai-proxy.md) |
| BUG-03 | **Low** | Firebase user enumeration | [BUG-03-firebase-user-enumeration.md](BUG-03-firebase-user-enumeration.md) |
| BUG-04 | **Low** | Public invite / demo / category endpoints | [BUG-04-public-endpoints.md](BUG-04-public-endpoints.md) |

## Unconfirmed (code-evidenced — need authenticated test / Firestore rules)

| ID | Potential | Title | File |
|----|-----------|-------|------|
| BUG-05 | Critical | Client self-assigns `paymentStatus`/`decisionStatus` | [BUG-05-client-payment-state.md](BUG-05-client-payment-state.md) |
| BUG-06 | High | Admin/chapter role is client-controlled (hardcoded allowlist) | [BUG-06-admin-role-client.md](BUG-06-admin-role-client.md) |
| BUG-07 | High | Predictable application document IDs → IDOR/PII | [BUG-07-predictable-app-ids.md](BUG-07-predictable-app-ids.md) |
| BUG-08 | High | Client-side RBAC in TeamFeed feeds/teams | [BUG-08-teamfeed-client-rbac.md](BUG-08-teamfeed-client-rbac.md) |
| BUG-09 | High/Med | Payment portal trusts `?app=` and `?return=` | [BUG-09-payment-portal-trust.md](BUG-09-payment-portal-trust.md) |

## Other
- Ably (separate authorized program): **no confirmed bugs** — see `ABLY-no-findings.md`.

> BUG-05..09 are **not proven**; they are source-review observations. Do not
> submit them as confirmed vulnerabilities without validation on a test account.