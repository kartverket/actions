#!/usr/bin/env bash

# Configuration
INPUTS_PATH=test-env/
INPUTS_REF=HEAD

GITHUB_OUTPUT=$(mktemp)
DIFF_SCRIPT=./diff.sh

# Export variables so the called script can read them
export INPUTS_REF INPUTS_PATH GITHUB_OUTPUT

# Execute
bash "${DIFF_SCRIPT}"

# Output results separately
echo "=== PROD DIFF ==="
sed -n '/^prod<<EOF$/,/^EOF$/p' "$GITHUB_OUTPUT" | sed '1d;$d'
echo ""
echo "=== DEV DIFF ==="
sed -n '/^dev<<EOF$/,/^EOF$/p' "$GITHUB_OUTPUT" | sed '1d;$d'

# Cleanup
rm -f "$GITHUB_OUTPUT"
