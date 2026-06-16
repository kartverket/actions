# OPA Check

Runs `opa check` against a Rego directory (or file) to verify policies parse
and type-check cleanly. Optionally validates references against JSON schemas to
catch typos in `input` field names and type mismatches before they reach
`opa test` or production. Writes a step summary and fails the step on any
check errors.

## Prerequisites

OPA is installed automatically when `opa` isn't already on PATH. To pin a
specific version, run
[`open-policy-agent/setup-opa`](https://github.com/open-policy-agent/setup-opa)
earlier in the calling workflow and the action will skip its own install step.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `path` | yes |  | Path to the Rego directory (or file) to check. Resolves relative to the workspace. |
| `schemas-path` | no | `''` | Path to a JSON Schema file or schema-set directory passed to `opa check -s`. When set, OPA type-checks references to `input` (and any mapped data documents) against the schema(s). |

## Behavior

- A missing `path` (or `schemas-path`, when set) fails fast with a clear error.
- `opa check` runs once. Its output is streamed to the job log live and
  captured to `opa-check-output.txt` for the step summary.
- On a successful check, `opa check` is silent — the summary shows
  `No errors.` in that case.
- On a failed check, OPA's diagnostic output is included verbatim in the
  summary inside a code block.
- `NO_COLOR=1` is set during the run, so the captured output is plain text
  without ANSI escape codes.

## Example

Basic usage — parse/compile check only:

```yaml
- uses: actions/checkout@<sha>
- uses: kartverket/actions/opa/check@<sha>
  with:
    path: opa
```

With schema validation — type-checks `input.*` references against a JSON Schema:

```yaml
- uses: kartverket/actions/opa/check@<sha>
  with:
    path: opa
    schemas-path: opa/schemas/input.json
```

Using a schema-set directory (multiple schemas mapped to different data paths):

```yaml
- uses: kartverket/actions/opa/check@<sha>
  with:
    path: opa
    schemas-path: opa/schemas
```

## When to use this alongside the other OPA actions

`opa/check` complements the other actions:

- **`opa/lint`** — Regal-based style and idiomatic-Rego checks (SARIF, Code Scanning).
- **`opa/check`** — OPA's own parser + optional schema type-checking.
- **`opa/test`** — runs unit tests and reports coverage.
- **`opa/build-push`** — bundles policies and (optionally) pushes them to GHCR.

A typical pipeline runs check + lint + test before build-push.
