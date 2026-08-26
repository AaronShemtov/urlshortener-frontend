#!/usr/bin/env bash
# Portable test script for shortcode redirects

set -euo pipefail

BASE_URL=${1:-http://localhost:8080}

echo "Using BASE_URL=${BASE_URL}"

post_response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"url":"https://example.com/long/path"}' "${BASE_URL}/shorten")

# Try jq first
if command -v jq >/dev/null 2>&1; then
  CODE=$(echo "$post_response" | jq -r '.code')
else
  # Fallback to grep/sed parsing for simple JSON like {"code":"abc123"}
  CODE=$(echo "$post_response" | tr -d ' \n\r' | sed -n 's/.*"code"\s*:\s*"\([^"]\+\)".*/\1/p')
fi

if [ -z "${CODE}" ] || [ "${CODE}" = "null" ]; then
  echo "Failed to extract code from response: ${post_response}" >&2
  exit 2
fi

echo "Got code: ${CODE}"

# Perform HEAD request without following redirects
resp_headers=$(curl -I --location-trusted --max-redirs 0 --silent --show-error "${BASE_URL}/${CODE}" || true)

# Extract HTTP status from response (first line)
status_line=$(echo "$resp_headers" | head -n1 | tr -d '\r')
status=$(echo "$status_line" | awk '{print $2}')

location_header=$(echo "$resp_headers" | grep -i '^Location:' | sed 's/[Ll]ocation:[[:space:]]*//') || location_header=""

echo "Status: ${status}"
echo "Location: ${location_header}"

if [ "$status" != "301" ]; then
  echo "Expected 301 redirect, got: ${status}" >&2
  exit 3
fi

if [[ "$location_header" != *"example.com/long/path"* ]]; then
  echo "Location header does not contain expected long URL: ${location_header}" >&2
  exit 4
fi

echo "Redirect test successful: ${BASE_URL}/${CODE} -> ${location_header}"
exit 0
#!/usr/bin/env bash
# Test redirect through the frontend for a given shortcode.
# Usage: ./scripts/test-redirect.sh SHORTCODE [FRONTEND_URL]
# Example: ./scripts/test-redirect.sh abc123 http://localhost:8080

set -euo pipefail

SHORTCODE=${1:-}
FRONTEND_URL=${2:-http://localhost:8080}

if [[ -z "$SHORTCODE" ]]; then
  echo "Usage: $0 SHORTCODE [FRONTEND_URL]"
  exit 2
fi

URL="$FRONTEND_URL/$SHORTCODE"

# Perform a request without following redirects to capture the Location header
RESP_HEADERS=$(mktemp)
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" -D "$RESP_HEADERS" -I "$URL")

echo "Requested: $URL"
echo "HTTP status: $HTTP_CODE"

if [[ $HTTP_CODE -ge 300 && $HTTP_CODE -lt 400 ]]; then
  LOCATION=$(grep -i '^Location:' "$RESP_HEADERS" | sed -e 's/[Ll]ocation: //')
  echo "Redirect Location: $LOCATION"
  exit 0
else
  echo "No redirect (or unexpected status). Response headers:"
  cat "$RESP_HEADERS"
  exit 3
fi
