# BUG-04 — LOW: Public invite / demo / category endpoints

| Field | Value |
|---|---|
| ID | BUG-04 |
| Severity | **Low / Informational** |
| Asset | `https://teamfeed-server.onrender.com` |
| Endpoint(s) | `/api/invites/:token`, `/api/collab/invites/:token`, `/api/demo-shares/:id`, `/api/company-categories` |
| Auth required | **None** |
| Status | **CONFIRMED** |
| Keywords | information disclosure, oracle, invite token, demo share |

## Summary
Several endpoints return data/validity to unauthenticated callers.

## Steps to Reproduce
```bash
B=https://teamfeed-server.onrender.com
for p in /api/invites/test /api/collab/invites/test /api/demo-shares/test /api/company-categories; do
  echo "== $p"; curl -sS "$B$p"; echo
done
```
## Evidence
```
/api/invites/test         -> {"kind":null,"valid":false,"status":"not_found"}
/api/collab/invites/test  -> {"valid":false,"status":"not_found"}
/api/demo-shares/test     -> {"error":"not_found","message":"No such demo."}
/api/company-categories   -> {"categories":[ ... ]}
```
## Impact
- Token-validity oracle (if invite tokens are guessable) enabling enumeration/brute force.
- Minor metadata exposure (company category list — low sensitivity).

## Recommended Fix
Rate-limit and/or authenticate these endpoints; return uniform responses.

## Handling
Only a non-existent token/id was used.