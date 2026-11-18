# BUG-08 — UNCONFIRMED (Potential High): Client-side RBAC in TeamFeed feeds/teams

> **STATUS: NOT CONFIRMED.** Source-review only; depends on Firestore rules.

| Field | Value |
|---|---|
| ID | BUG-08 |
| Potential Severity | **High** |
| Asset | `teamfeed.co` SPA → Firestore `tfFeeds`, `tfTeams` |
| Location | `feedMutations` chunk |
| Keywords | privilege escalation, IDOR, broken access control, feeds, teams |

## Observation
The client derives the caller's role from document fields and writes feed/team
membership itself:
- role from `participants[].role` ("aply"/"brand"/"creators"),
  `adminIds[]`, `memberIds[]`, `members[].role`
- writes e.g. `` setDoc(feedRef, {[`members.${id}`]:{role:"member",approved:true,...}} , {merge:true}) ``

## Potential Impact
If rules allow a member to write `adminIds`/`memberIds`/`participants`/`members`
on a feed/team doc, they can self-elevate to admin (rosters, real names, payouts,
admin actions).

## How to validate (authorized test account only)
1. Create a feed/team as test user A; add test user B.
2. As B, attempt to write `adminIds`/`members.<B>.role = "admin"`.
3. Observe whether the write succeeds and grants elevated UI/data access.

## Recommended Fix
Enforce roles server-side (custom claims or server checks); rules must not trust
client-writable `adminIds`/`memberIds`/`members`.