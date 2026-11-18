# Ably — Authorized Assessment: No Confirmed Findings

| Field | Value |
|---|---|
| Program | Ably VDP — https://ably.com/disclosure — disclosure@ably.com |
| Payouts | Low=recognition, Medium=$500, High=$1,000, Critical=$3,000 |
| Status | **No confirmed vulnerabilities** |

## Scope tested
- `ably.com` + ancillary `*.ably.com` (operated by Ably, not internal)
- `control.ably.net`, `rest.ably.io`, `main.realtime.ably.net`, `realtime.ably.io`
- Out of scope: SDKs, ably-cli/ably-server, third-party hosts (Intercom,
  support.ably.com, SafeBase security.ably.com, HubSpot pages, status.ably.com),
  internal/non-customer-facing (`ai-assistant.ably.com`).

## Tests performed (all negative)
- Subdomain takeover across ~35 hosts + CNAME chains → none dangling.
- Exposed files / source maps / verbose errors → none.
- Reflected/DOM XSS (`/search`, `/docs`) → none.
- Next.js middleware auth-bypass (CVE-2025-29927) → patched (307 to login).
- Image-optimizer SSRF → no optimizer / internal URLs rejected.
- Integration-rules SSRF → `422 "Disallowed IP address"` (127.0.0.1, localhost,
  10/192.168/169.254, [::1], decimal/hex/octal/nip.io/sslip.io); no bypass.
- Capability bounding (key→token, signed + unsigned) → capped per spec.
- Channel-scope escape (encodings/traversal/wildcards) → denied.
- Token revocation (REST + live WebSocket) → enforced (401; live socket closed).
- Cross-tenant IDOR (app/keys/queues/rules/namespaces) → 404 / isolation holds.
- Account-token capability boundary (`read:app` absent) → 401 enforced.

## Conclusion
No vulnerability was found in the reachable in-scope surface. Ably's historical
criticals (RCE, SSRF, realtime auth bypass, queue IDOR, token-revocation bypass)
appear fixed. Nothing to submit.

## Cleanup
Temporary test keys created during revocation tests were revoked
(`status=1`); all test rules deleted. No account data modified otherwise.