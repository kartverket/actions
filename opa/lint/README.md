# OPA Lint

Runs [Regal](https://www.openpolicyagent.org/projects/regal) against a Rego
directory (or file), emits a SARIF report, writes a step summary, and fails the
step on any violations. The SARIF report is uploaded to GitHub Code Scanning by
default so violations appear inline in PR diffs and as alerts in the Security
tab.

## Prerequisites

Regal is installed automatically when `regal` isn't already on PATH. To pin a
specific version, run
[`open-policy-agent/setup-regal`](https://github.com/open-policy-agent/setup-regal)
earlier in the calling workflow and the action will skip its own install step.

When `upload-sarif` is `'true'` (the default), the calling workflow needs
`security-events: write` in its `permissions` block. Private/internal repos
additionally need GitHub Advanced Security (GHAS).

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `path` | yes |  | Path to the Rego directory (or file) to lint. Resolves relative to the workspace. |
| `upload-sarif` | no | `'true'` | Whether to upload the SARIF report to GitHub Code Scanning. Set to `'false'` for repos without GHAS or when you don't want findings posted to the Security tab. |

## Outputs

The action does not declare outputs. The SARIF report is written to
`regal-results.sarif` and the human-readable output to `regal-output.txt` in
the workspace if you need to consume either from a later step.

## Behavior

- Regal is invoked twice over the same path:
  1. `--format sarif` — captured to disk for the Code Scanning upload.
  2. Default (pretty) format — streamed to the job log live and captured for the step summary.
- A missing `path` fails fast with a clear error.
- On violations the action defers its `exit` until after the SARIF upload step
  runs, so findings still reach Code Scanning when the build is about to fail.
- The upload uses category `regal`, keeping Regal alerts separate from other
  SARIF producers (CodeQL, Trivy, etc.) in the same repo.

## Example

Default usage — fail on violations and upload findings to Code Scanning:

```yaml
permissions:
  contents: read
  security-events: write   # required by upload-sarif: 'true' (the default)

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: kartverket/actions/opa/lint@<sha>
        with:
          path: opa
```

Skipping the upload (e.g. for a fork or a repo without GHAS):

```yaml
- uses: kartverket/actions/opa/lint@<sha>
  with:
    path: opa
    upload-sarif: 'false'
```
