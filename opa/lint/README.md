# OPA Lint

Runs [Regal](https://www.openpolicyagent.org/projects/regal) against a Rego directory (or file),
captures the results as JSON for downstream consumption (e.g. building a step
summary), and fails the step on any violations.

## Prerequisites

Regal must already be installed on the runner. Set it up earlier in the workflow
with [`open-policy-agent/setup-regal`](https://github.com/open-policy-agent/setup-regal).

## Inputs

| Name        | Required | Description                                                                       |
|-------------|----------|-----------------------------------------------------------------------------------|
| `rego-path` | yes      | Path to the Rego directory (or file) to lint. Resolves relative to the workspace. |

## Outputs

| Name           | Description                                                                                   |
|----------------|-----------------------------------------------------------------------------------------------|
| `results-file` | Path of the Regal JSON report (always `regal-results.json` in the workspace).                 |
| `exit-code`    | Regal exit code as a string. `"0"` means no violations; non-zero means violations were found. |

The JSON file conforms to Regal's `--format json` schema and includes a
`violations` array (file, rule, level, description) plus a `summary` block.
Read it from a later step that builds a markdown table or filters violations by
severity.

## Behavior

- The action runs Regal twice over the same path: once with `--format json`
  (output captured to disk), once with default output (streamed to the job log
  so violations are visible while the run is in progress).
- A missing path fails fast with a clear error rather than letting Regal
  produce a confusing message.
- On violations Regal exits non-zero. The action mirrors that as a step failure
  via `core.setFailed`, so downstream steps with no explicit `if:` will be
  skipped. Use `if: always()` on summary or reporting steps that should still run.

## Example

```yaml
- uses: open-policy-agent/setup-regal@<sha>
- uses: kartverket/actions/opa/lint@<sha>
  with:
    rego-path: policies
```
