#!/usr/bin/env bash
set -euo pipefail

DECRYPTED_ENV_FILE="${1:-}"

fail() {
  echo "Error: $*" >&2
  exit 1
}

[ -n "${DECRYPTED_ENV_FILE}" ] || fail "Usage: $0 <env-file>"
[ -f "${DECRYPTED_ENV_FILE}" ] || fail "Secret env file not found: ${DECRYPTED_ENV_FILE}"

set -a
# shellcheck disable=SC1090
source "${DECRYPTED_ENV_FILE}"
set +a

python3 - "${DECRYPTED_ENV_FILE}" <<'PY'
import json
import os
import sys

env_file = sys.argv[1]
raw = os.environ.get("TF_VAR_api_secure_parameters", "").strip()

if not raw:
    print(
        f"Error: {env_file} must define TF_VAR_api_secure_parameters with a JSON object.",
        file=sys.stderr,
    )
    sys.exit(1)

try:
    payload = json.loads(raw)
except json.JSONDecodeError as exc:
    print(
        f"Error: TF_VAR_api_secure_parameters in {env_file} is not valid JSON: {exc}",
        file=sys.stderr,
    )
    sys.exit(1)
PY
