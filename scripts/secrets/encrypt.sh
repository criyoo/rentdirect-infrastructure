#!/bin/bash

set -euo pipefail

WORKSPACE="${1:-dev}"
AGE_KEY_FILE="${AGE_KEY_FILE:-${HOME}/.config/age/rentdirect/keys.txt}"
AGE_DECRYPTED_FILE="terraform/envs/secrets/.env.${WORKSPACE}"
AGE_ENCRYPTED_FILE="terraform/envs/secrets/.env.${WORKSPACE}.age"

if ! command -v age >/dev/null 2>&1; then
    echo "Error: 'age' is not installed."
    echo "Install it first, then rerun this command."
    exit 1
fi

if [ ! -f "$AGE_DECRYPTED_FILE" ]; then
    echo "Error: $AGE_DECRYPTED_FILE not found."
    exit 1
fi

if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "Error: age key not found at $AGE_KEY_FILE"
    echo "Run: bash scripts/setup.sh"
    exit 1
fi

PUBLIC_KEY="$(age-keygen -y "$AGE_KEY_FILE")"

echo "Encrypting $AGE_DECRYPTED_FILE..."
age -R <(echo "$PUBLIC_KEY") "$AGE_DECRYPTED_FILE" > "$AGE_ENCRYPTED_FILE"
chmod 600 "$AGE_ENCRYPTED_FILE"

echo "Encrypted to $AGE_ENCRYPTED_FILE"
