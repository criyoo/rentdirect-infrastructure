#!/bin/bash

set -euo pipefail

AGE_KEY_DIR="${HOME}/.config/age/rentdirect"
AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"

if ! command -v age-keygen >/dev/null 2>&1; then
    echo "Error: 'age-keygen' is not installed."
    echo "Install age first, then rerun this command."
    exit 1
fi

mkdir -p "$AGE_KEY_DIR"

if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "Generating age key at $AGE_KEY_FILE..."
    age-keygen -o "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
else
    echo "Age key already exists at $AGE_KEY_FILE"
fi

echo ""
echo "Recipient:"
age-keygen -y "$AGE_KEY_FILE"
