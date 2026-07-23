#!/bin/bash

set -euo pipefail

WORKSPACE="${1:-dev}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
AGE_KEY_FILE="${AGE_KEY_FILE:-${HOME}/.config/age/rentdirect/keys.txt}"
AGE_DECRYPTED_FILE="${INFRA_DIR}/terraform/envs/secrets/.env.${WORKSPACE}"
AGE_ENCRYPTED_FILE="${AGE_DECRYPTED_FILE}.age"

if ! command -v age >/dev/null 2>&1; then
    echo "Error: 'age' is not installed."
    echo "Install it first, then rerun this command."
    exit 1
fi

if [ -f "$AGE_ENCRYPTED_FILE" ] && [ ! -f "$AGE_DECRYPTED_FILE" ]; then
    if [ ! -f "$AGE_KEY_FILE" ]; then
        echo "Error: age key not found at $AGE_KEY_FILE"
        echo "Run: make setup"
        exit 1
    fi

    echo "Decrypting $AGE_ENCRYPTED_FILE..."
    age -d -i "$AGE_KEY_FILE" "$AGE_ENCRYPTED_FILE" > "$AGE_DECRYPTED_FILE"
    chmod 600 "$AGE_DECRYPTED_FILE"
fi

if [ ! -f "$AGE_DECRYPTED_FILE" ]; then
    echo "Error: neither $AGE_DECRYPTED_FILE nor $AGE_ENCRYPTED_FILE exists."
    echo "Copy $(basename "$AGE_DECRYPTED_FILE").example to $(basename "$AGE_DECRYPTED_FILE") and add your local secrets."
    exit 1
fi

echo "Environment file ready: $AGE_DECRYPTED_FILE"
