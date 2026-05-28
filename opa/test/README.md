# opa-test

Runs `opa test` against a Rego directory (or file), capturing both test
results and coverage as JSON files for downstream consumption. Fails the step
on any failing tests. Coverage capture is best-effort and does not affect step
outcome on its own.

## Prerequisites

OPA must already be installed on the runner. Set it up earlier in the workflow
with [`open-policy-agent/setup-opa`](https://github.com/open-policy-agent/setup-opa).

## Inputs

| Name | Required | Description |
|------|----------|-------------|
| `test-path` | yes | Path to the Rego directory (or file) to test. Resolves relative to the workspace. |

## Outputs

| Name | Description |
|------|-------------|
| `results-file` | Path of the test results JSON (always `opa-test-results.json` in the workspace). |
| `coverage-file` | Path of the coverage JSON (always `opa-coverage.json` in the workspace). |
| `exit-code` | `opa test` exit code as a string. `"0"` means all tests passed. |

Both files are written in the formats OPA emits when called with
`--format=json` (results) and `--coverage --format=json` (coverage).

## Behavior

- A missing path fails fast with a clear error.
- OPA quirk: passing `--coverage` together with `--format=json` *replaces* the
  test-result JSON with a coverage-only JSON. To capture both, this action runs
  `opa test` twice. The first run determines step success; the second is
  best-effort and never fails the step on its own.
- `--fail-on-empty` is passed so a run where no tests were discovered counts as
  a failure (catches typos in `test-path` and missing test files).
- Per-test status and overall coverage are echoed to the job log as the run
  progresses, before the JSON files are read by a later summary step.
- On failures the action mirrors the non-zero exit code as a step failure via
  `core.setFailed`. Use `if: always()` on summary steps that should still render.

## Example

```yaml
- uses: open-policy-agent/setup-opa@<sha>
- uses: kartverket/actions/opa/opa-test@<sha>
  with:
    test-path: policies
```

Reading the outputs in a later step:

```yaml
- uses: kartverket/actions/opa/opa-test@<sha>
  id: test
  with:
    test-path: policies

- if: always()
  uses: actions/upload-artifact@<sha>
  with:
    name: opa-test-results
    path: |
      ${{ steps.test.outputs.results-file }}
      ${{ steps.test.outputs.coverage-file }}
```
