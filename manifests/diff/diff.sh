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
    done < <(find "${INPUTS_PATH}" -type d -name "$pattern" -print0 | sort -z)

    echo "$output"
}

# Discover all unique suffixes from directory names
suffixes=()
while IFS= read -r dir; do
    basename=$(basename "$dir")
    # Extract suffix after last hyphen
    if [[ "$basename" =~ -([^-]+)$ ]]; then
        suffix="${BASH_REMATCH[1]}"
        # Add to array if not already present
        if [[ ${#suffixes[@]} -eq 0 ]] || [[ ! " ${suffixes[@]} " =~ " ${suffix} " ]]; then
            suffixes+=("$suffix")
        fi
    fi
done < <(find "${INPUTS_PATH}" -maxdepth 1 -mindepth 1 -type d -name '*-*')

for suffix in "${suffixes[@]}"; do
    echo "found: ${suffix}"
done

# Generate diff output for each suffix in parallel
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for suffix in "${suffixes[@]}"; do
    (
        diff_output="$(generate_diff_output "*-${suffix}")"
        {
            echo "${suffix}<<EOF"
            printf '%s\n' "$diff_output"
            echo 'EOF'
        } > "$tmpdir/${suffix}.out"
    ) &
done

wait

# Write outputs to GITHUB_OUTPUT in consistent order
for suffix in "${suffixes[@]}"; do
    cat "$tmpdir/${suffix}.out"
done >> "$GITHUB_OUTPUT"

rm -rf "$tmpdir"
