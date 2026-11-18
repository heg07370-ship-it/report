# BUG-02 — MEDIUM: Unauthenticated, unrate-limited AI proxy

| Field | Value |
|---|---|
| ID | BUG-02 |
| Severity | **Medium** |
| CVSS v3.1 | `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L` (**5.3**) |
| Asset | `https://aply-server.onrender.com` |
| Endpoint(s) | `/ai/enrich-company`, `/ai/evaluate-lane-fit` |
| Auth required | **None** |
| Status | **CONFIRMED** |
| Keywords | unauthenticated, LLM, cost abuse, rate limit, business logic |

## Summary
Two LLM-backed endpoints are callable without authentication and show no rate
limiting. The browser client calls them directly.

## Steps to Reproduce
```bash
for i in 1 2 3; do
  curl -sS -o /dev/null -w "%{http_code} " -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"probe $i\"}" \
    https://aply-server.onrender.com/ai/enrich-company
done; echo
```
## Evidence
```
200 200 200        # ~2s each, no auth, no throttle
{"ok":true,"bio":"probe 1 provides ..."}
```
`/ai/evaluate-lane-fit` returns a gate-decision object (business-logic oracle).

## Impact
- Unbounded LLM **cost abuse / resource exhaustion**.
- Gate-decision oracle for `evaluate-lane-fit`.
- (Prompt-injection attempt against `enrich-company` was refused; no system-prompt leak observed.)

## Recommended Fix
Require auth, per-user/IP rate limits, token caps, input validation, spend monitoring.

## Handling
Benign probes only; no abuse performed.