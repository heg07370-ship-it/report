# BUG-05 — UNCONFIRMED (Potential Critical): Client self-assigns paid/accepted state

> **STATUS: NOT CONFIRMED.** Source-review only. Exploitability depends on
> Firestore security rules (not tested). Do not submit as a confirmed vuln
> without validation on a **test account**.

| Field | Value |
|---|---|
| ID | BUG-05 |
| Potential Severity | **Critical** (if rules permit) |
| Asset | `aply.com` SPA → Firestore `Applications` |
| Location | `/assets/Pipeline-Jc2L2Pp1.js` |
| Keywords | business logic, payment bypass, Firestore rules, client-side trust |

## Observation
On the pipeline "join"/"UGC join" flow the client writes the paid/accepted flags
directly to Firestore:
```js
Y = () => doc(db, "Applications", `${Op(email)}_${pipelineId}`)
H = () => setDoc(Y(), {
  pipelineId: S, email: r.email, userId: i,
  paymentStatus: "balance_paid",     // paid flag set by client
  decisionStatus: "active",          // accepted flag set by client
  submittedAt: serverTimestamp(), updatedAt: serverTimestamp()
}, { merge: true })
```
The paid gate then trusts these fields:
```js
["deposit_paid","balance_paid"].includes(paymentStatus)
 && ["accepted","active"].includes(decisionStatus)
```
(Minified alias verified: `xt` → `setDoc`; `V` → `doc`.)

## Potential Impact
If Firestore rules allow the applicant to write `paymentStatus`/`decisionStatus`
on their own doc, a candidate can self-activate **paid + accepted** status and
unlock paid contracts / paid course without paying — bypassing "only pay for
results" and the $400 balance.

## How to validate (authorized test account only)
1. Register a test user.
2. Trigger the join flow; inspect `Applications/{normalize(email)}_{pipelineId}`.
3. Check whether `paymentStatus`/`decisionStatus` are client-writable.
4. Verify paid-gated views unlock.

## Recommended Fix
Move state transitions server-side (Cloud Function + Admin SDK); rules must deny
client writes to `paymentStatus`, `decisionStatus`, and entitlement fields.