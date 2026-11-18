# BUG-07 — UNCONFIRMED (Potential High): Predictable application IDs → IDOR/PII

> **STATUS: Partially confirmed (ID scheme) / read-scope unverified.**
> The ID format is confirmed from source; whether other users' docs are readable
> depends on Firestore rules (not tested).

| Field | Value |
|---|---|
| ID | BUG-07 |
| Potential Severity | **High** |
| Asset | Firestore `Applications` (project `mrkt-2efde`) |
| Location | `/assets/Pipeline-Jc2L2Pp1.js` (normalizer `Op`) |
| Keywords | IDOR, predictable IDs, PII, data exposure, enumeration |

## Observation
```js
Op = (n="") => n.toLowerCase().replace(/[^a-z0-9]+/g,"_").replace(/^_+|_+$/g,"")
doc id = `${Op(email)}_${pipelineId}`
```
Application docs contain `email`, `userId`, `paymentStatus`, `decisionStatus`,
`submittedAt`, plus portfolio/UGC data. IDs are derivable (no randomness).

## Potential Impact
If rules allow any authenticated user to read `Applications`, an attacker can
derive IDs and read other applicants' PII/hiring/payment data (privacy-law
exposure, doxxing, phishing).

## How to validate (authorized test account only)
1. With test user A, create an application.
2. With test user B, attempt to read A's doc using the derived ID.
3. Record allow/deny.

## Recommended Fix
- Use random document IDs (Firestore auto-ID).
- Scope reads to owner (`request.auth.uid == resource.data.userId`) or the
  authorized employer for the pipeline.
- Avoid PII in document IDs.

## Relation
This amplifies **BUG-01** (unauth Stripe): predictable IDs + unauth money ops.