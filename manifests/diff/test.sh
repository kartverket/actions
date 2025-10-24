#!/usr/bin/env bash

# Configuration
INPUTS_PATH=test-env/
INPUTS_REF=HEAD

GITHUB_OUTPUT=/dev/stdout
DIFF_SCRIPT=./diff.sh

# Export variables so the called script can read them
export INPUTS_REF INPUTS_PATH GITHUB_OUTPUT

# Execute
bash "${DIFF_SCRIPT}"
