# BUG-06 — UNCONFIRMED (Potential High): Client-controlled admin/chapter role

> **STATUS: NOT CONFIRMED.** Source-review only. Exploitability depends on
> Firestore rules (not tested). Validate on a test account before reporting.

| Field | Value |
|---|---|
| ID | BUG-06 |
| Potential Severity | **High** (if rules trust client fields) |
| Asset | `aply.com` SPA (sorority/chapter, admin, courses) |
| Keywords | privilege escalation, broken authorization, client-side trust, admin |

## Observation
- Admin UI is gated by a **hardcoded client-side email allowlist**:
  ```js
  const k = ["nd@aply.com"];
  const T = e => !!e && k.includes(e.toLowerCase());   // "admin" : "denied"
  ```
  (Discloses the sole admin identity.)
- Roles are written from the browser with merge:
  ```js
  setDoc(memberRef, { role: "leadership", isAdmin: <bool>, joinedAt: ... }, { merge: true })
  ```
- Admin screens: `/admin/ugc-approvals`, `/admin/course/:courseId`.

## Potential Impact
If security rules trust client-written `role`/`isAdmin`, any authenticated member
can elevate to chapter leadership/admin → approve UGC, edit courses, manage
chapters, message members.

## How to validate (authorized test account only)
1. As a normal test member, attempt to write `isAdmin:true` / `role:"leadership"`
   to your own member doc.
2. Load `/admin/ugc-approvals` and attempt an approval action.
3. Confirm server-side enforcement (or lack of).

## Recommended Fix
Use Firebase **custom claims** (`admin`, `role`) set server-side; rules check
`request.auth.token.*`; remove hardcoded admin emails from the client.