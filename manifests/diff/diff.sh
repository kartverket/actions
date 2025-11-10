#!/bin/bash
set -euo pipefail

# Function to generate diff output with individual file toggles
generate_diff_output() {
    local pattern=$1
    local output=""

    # First find all directories matching the pattern, then find files in them
    while IFS= read -r -d '' dir; do
        while IFS= read -r -d '' file; do
            local diff_result
            diff_result=$(skipctl manifests diff -p "$file" --ref "${INPUTS_REF}" --diff-format patch 2>/dev/null || true)

            if [ -n "$diff_result" ]; then
                local file_path="$file"
                # Remove the input path prefix for cleaner display
                local display_path="${file_path#${INPUTS_PATH}/}"

                output+="<details>"
                output+=$'\n'
                output+="  <summary><b>$display_path DIFF</b></summary>"
                output+=$'\n'
                output+=$'\n'
                output+='```diff'
                output+=$'\n'
                output+="$diff_result"
                output+=$'\n'
                output+='```'
                output+=$'\n'
                output+="</details>"
                output+=$'\n'
            fi
        done < <(find "$dir" -type f -print0 | sort -z)
    done < <(find "${INPUTS_PATH}" -maxdepth 1 -type d -name "$pattern" -print0 | sort -z)

    echo "$output"
}

DIFF_OUTPUT_PROD="$(generate_diff_output '*-prod')"
DIFF_OUTPUT_DEV="$(generate_diff_output '*-dev')"

# Set outputs using GitHub Actions output syntax
{
    echo 'prod<<EOF'
    printf '%s\n' "$DIFF_OUTPUT_PROD"
    echo 'EOF'
    echo 'dev<<EOF'
    printf '%s\n' "$DIFF_OUTPUT_DEV"
    echo 'EOF'
} >> "$GITHUB_OUTPUT"
