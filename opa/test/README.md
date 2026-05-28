# OPA Test

Runs `opa test` against a Rego directory (or file), captures the human-readable
results and the overall coverage percentage, writes a step summary, and fails
the step on any failing tests.

## Prerequisites

OPA is installed automatically when `opa` isn't already on PATH. To pin a
specific version, run
[`open-policy-agent/setup-opa`](https://github.com/open-policy-agent/setup-opa)
earlier in the calling workflow and the action will skip its own install step.

## Inputs

| Name | Required | Description |
|------|----------|-------------|
| `path` | yes | Path to the Rego directory (or file) to test. Resolves relative to the workspace. |

## Outputs

| Name | Description |
|------|-------------|
| `results-file` | Path of the human-readable test output (always `opa-test-output.txt` in the workspace). |
| `coverage` | Overall test coverage as a number (e.g. `85.7`). Extracted from `opa test --coverage --format=json` and falls back to `0` if it can't be parsed. |
| `exit-code` | `opa test` exit code as a string. `"0"` means all tests passed. |

## Behavior

- A missing `path` fails fast with a clear error.
- The action runs `opa test` twice:
  1. `--coverage --format=json` — output parsed with `jq` to extract the
     overall coverage percentage. Best-effort: if the JSON can't be parsed,
     the `coverage` output falls back to `0` without failing the step.
  2. `--fail-on-empty` (default format) — streamed to the job log live and
     captured to `opa-test-output.txt` for the step summary. This run also
     determines the step's success/failure.
- `--fail-on-empty` ensures a run that discovers no tests counts as a failure,
  catching typos in `path` and missing test files.
- The step summary embeds the test output verbatim plus the coverage
  percentage on a separate line.

## Example

```yaml
- uses: actions/checkout@<sha>
- uses: kartverket/actions/opa/test@<sha>
  id: test
  with:
    path: opa

- run: echo "Coverage was ${{ steps.test.outputs.coverage }}%"
```

Uploading the test output as an artifact for later inspection:

```yaml
- uses: kartverket/actions/opa/test@<sha>
  id: test
  with:
    path: opa

- if: always()
  uses: actions/upload-artifact@<sha>
  with:
    name: opa-test-output
    path: ${{ steps.test.outputs.results-file }}
```
