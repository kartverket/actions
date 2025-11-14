#!/usr/bin/env bash

# Configuration
INPUTS_PATH=./test-env
INPUTS_REF=HEAD

GITHUB_OUTPUT=$(mktemp)
DIFF_SCRIPT=./diff.sh

# Export variables so the called script can read them
export INPUTS_REF INPUTS_PATH GITHUB_OUTPUT

# Execute
bash "${DIFF_SCRIPT}"

# Extract all suffixes from output and display them
echo "=== DISCOVERED SUFFIXES ==="
grep '<<EOF$' "$GITHUB_OUTPUT" | sed 's/<<EOF$//' | tr '\n' ' '
echo -e "\n"

# Output results for each suffix
while IFS= read -r suffix; do
    echo "=== $(echo "$suffix" | tr '[:lower:]' '[:upper:]') DIFF ==="
    sed -n "/^${suffix}<<EOF$/,/^EOF$/p" "$GITHUB_OUTPUT" | sed '1d;$d'
    echo ""
done < <(grep '<<EOF$' "$GITHUB_OUTPUT" | sed 's/<<EOF$//')

# Cleanup
rm -f "$GITHUB_OUTPUT"
