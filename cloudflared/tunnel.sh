#!/bin/sh
set -eu

API_ORIGIN_URL="${API_ORIGIN_URL:-http://api:8600}"
LOG_FILE="${CLOUDFLARE_LOG_FILE:-/data/cloudflare/cloudflared.log}"
TUNNEL_FILE="${CLOUDFLARE_TUNNEL_URL_FILE:-/data/cloudflared/tunnel-url}"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$TUNNEL_FILE")"

rm -f "$TUNNEL_FILE" "${TUNNEL_FILE}.tmp"
: > "$LOG_FILE"

echo "Starting Cloudflare Quick Tunnel"
echo "Forwarding tunnel traffic to: $API_ORIGIN_URL"

cloudflared tunnel \
  --no-autoupdate \
  --url "$API_ORIGIN_URL" \
  2>&1 |
tee -a "$LOG_FILE" |
while IFS= read -r line; do
  echo "$line"

  tunnel_url="$(
    printf '%s\n' "$line" |
    grep -oE 'https://[-a-zA-Z0-9]+\.trycloudflare\.com' |
    head -n 1 ||
    true
  )"

  if [ -z "$tunnel_url" ]; then
    continue
  fi

  printf '%s\n' "$tunnel_url" > "${TUNNEL_FILE}.tmp"
  mv "${TUNNEL_FILE}.tmp" "$TUNNEL_FILE"

  echo "Cloudflare tunnel URL saved to $TUNNEL_FILE"
  echo "Tunnel URL: $tunnel_url"
done