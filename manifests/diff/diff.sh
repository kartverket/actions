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

# Discover all unique suffixes from directory names
suffixes=()
invalids=()
while IFS= read -r dir; do
    basename=$(basename "$dir")
    # Extract suffix after last hyphen
    if [[ "$basename" =~ -([^-]+)$ ]]; then
        suffix="${BASH_REMATCH[1]}"
        # Add to array if not already present
        if [[ ${#suffixes[@]} -eq 0 ]] || [[ ! " ${suffixes[@]} " =~ " ${suffix} " ]]; then
            suffixes+=("$suffix")
        fi
    # Add into invalids if wrong suffix is used
    else 
        invalids+=("$basename") 
    fi
done < <(find "${INPUTS_PATH}" -maxdepth 1 -mindepth 1 -type d)

# Prompt the invalid suffixes so the user can fix them. The correct format is dash suffixes
if [[ ${#invalids[@]i} -gt 0 ]];then
    echo "Found invalid cluster name(s):"
    echo "-----------------------------"
    for invalid in "${invalids[@]}"; do
         echo "The cluster name: ${invalid} is invalid"
    done
        echo
        echo "Please note that all cluster names should have the dash suffix (-)."
        echo "Examples: \"-prod\",\"-dev\" and \"-sandbox\"".
    echo "-----------------------------"
fi

for suffix in "${suffixes[@]}"; do
    echo "found: ${suffix}"
done

# Generate diff output for each suffix in parallel
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Process each suffix concurretly for improved performance on large repositories
# Background execution (&) significantly reduces processing time for extensive configurations
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

# Combine outputs into prod and other categories
prod_output=""
other_output=""

for suffix in "${suffixes[@]}"; do
    content=$(cat "$tmpdir/${suffix}.out")
    # Extract the actual diff content (everything between first newline and EOF)
    diff_content=$(echo "$content" | sed '1d;$d')
    
    if [ "$suffix" = "prod" ]; then
        prod_output+="$diff_content"
    else
        if [ -n "$diff_content" ]; then
            # Add environment header for non-prod
            other_output+=$'\n'
            other_output+="## ${suffix}"
            other_output+=$'\n'
            other_output+="$diff_content"
            other_output+=$'\n'
        fi
    fi
done

# Write grouped outputs to GITHUB_OUTPUT
{
    echo "prod<<EOF"
    printf '%s\n' "$prod_output"
    echo 'EOF'
    echo "other<<EOF"
    printf '%s\n' "$other_output"
    echo 'EOF'
} >> "$GITHUB_OUTPUT"

rm -rf "$tmpdir"