# BUG-09 — UNCONFIRMED (Potential High/Medium): Payment portal trusts URL params

> **STATUS: NOT CONFIRMED.** Source-review only. Confirmation would require
> creating a real Stripe session (owner permission). Do not test on real users.

| Field | Value |
|---|---|
| ID | BUG-09 |
| Potential Severity | **High/Medium** |
| Asset | `teamfeed.co` payment portal → `/api/stripe/create-checkout-session` |
| Location | `PaymentPortalPage` chunk |
| Keywords | open redirect, parameter tampering, payment, application forgery |

## Observation
Route: `/pay?app=<base64url JSON>&return=<url>`
```js
applicationData = decodeBase64Url(searchParams.get("app"))   // client-controlled
returnUrl       = searchParams.get("return")                 // client-controlled
fetch(`${server}/api/stripe/create-checkout-session`, {
  method:"POST", headers:{"Content-Type":"application/json"},
  body: JSON.stringify({ pipelineId, applicationData, returnUrl })   // NO Authorization
})
```

## Potential Impact
- `applicationData` is the applicant identity payload for the `$99` deposit and
  is fully client-controlled → possible applicant-data forgery / attribution.
- `returnUrl` is forwarded to Stripe session creation → possible **open redirect**
  after payment (phishing) if not allowlisted.
- No auth → session-creation spam.

## How to validate (owner permission only)
- Create one checkout session with a benign `pipelineId` and observe whether
  `returnUrl` is reflected/used and whether `applicationData` is persisted.
- **Do not** use real applicant data or trigger refunds/charges.

## Recommended Fix
Authenticate the call; derive applicant identity from the authenticated user
(never `?app=`); allowlist `returnUrl`; rate-limit.