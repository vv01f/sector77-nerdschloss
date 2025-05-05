#!/usr/bin/env sh
# check dependencies
dependencies="openssl awk sed" # base64 command mitigated with fallback function
err=0; errmsg=""
for c in $(printf "$dependencies"); do
  command -v "$c" >/dev/null || { err=1; errmsg = "${errmsg}%s\r\n" "command missing: ${c}"; }
done
[ $err -eq 0 ] || {
  printf "WWW-Authenticate: Basic realm=\"%s\"\r\n" "$REALM"
  printf "Status: 500 Internal Server Error\r\n"
  printf "Content-Type: text/plain\r\n\r\n"
  printf "Server misconfiguration: commands missing\n"
  exit 0;
} 

# Constants
PW_HASH='<sha512-hash>'
REALM="section77"
EXPECTED_USER="nerdschloss"

# send 401 Unauthorized
unauthorized() {
  printf "WWW-Authenticate: Basic realm=\"%s\"\r\n" "$REALM"
  printf "Status: 401 Unauthorized\r\n"
  printf "Content-Type: text/plain\r\n\r\n"
  printf "Unauthorized\n"
  exit 0
}

# assert on method not PUT
[ "$REQUEST_METHOD" = "PUT" ] || {
  printf "Content-Type: text/plain\r\n\r\n"
  printf "Invalid Method\n"
  exit 0
}

# Extract credentials
auth=$(printf "%s" "$HTTP_AUTHORIZATION" | cut -d' ' -f2)
[ -n "$auth" ] || unauthorized

decode_base64() {
  # decode base64 (assumes base64 is available)
  # possible alternatives:
  #   openssl base64 -d
  #   baseenc --base64 --decode
  #   perl -MMIME::Base64 -ne 'print decode_base64($_)'
  #   python3 -c "import base64,sys; print(base64.b64decode(sys.stdin.read()).decode())"
  #   busybox base64 -d
  if command -v base64 >/dev/null 2>&1; then
    base64 -d
  elif command -v openssl >/dev/null 2>&1; then
    openssl base64 -d
  elif command -v baseenc >/dev/null 2>&1; then
    baseenc --base64 --decode
  elif command -v perl >/dev/null 2>&1; then
    perl -MMIME::Base64 -ne 'print decode_base64($_)'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import base64,sys; print(base64.b64decode(sys.stdin.read()).decode(), end='')"
  else
    printf "%s\n" "Error: No base64 decoder found" >&2
    return 1
  fi
}

decoded=$(printf "%s" "$auth" | decode_base64 2>/dev/null)
user=$(printf "%s" "$decoded" | cut -d':' -f1)
pass=$(printf "%s" "$decoded" | cut -d':' -f2-)

[ "${user}" = "${EXPECTED_USER}" ] || {
  printf "Content-Type: text/plain\r\n\r\n"
  echo "Invalid user"
  exit 0
}

# compare constand hash and hashed password
pass_hash=$(printf "%s" "$pass" | openssl dgst -sha512 | awk '{print $2}')
[ "${pass_hash}" = "${PW_HASH}" ] || {
  printf "Content-Type: text/plain\r\n\r\n"
  printf "Invalid password\n"
  exit 0
}

# read query string (e.g., ?status=open)
status=$(printf "%s" "$QUERY_STRING" | sed -n 's/^.*status=\([^&]*\).*$/\1/p')

[ "${status}" = "open" ] || [ "${status}" = "closed" ] || {
  printf "Content-Type: text/plain\r\n\r\n"
  printf "%s\n" 'Status should be "open" or "closed"'
  exit 0
}

printf "%s\n" "${status}" > door_status.txt

printf "Content-Type: text/plain\r\n\r\n"
printf "Door status has been set to ${status}\n"
