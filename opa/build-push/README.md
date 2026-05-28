# OPA Build & Push

Builds an OPA bundle (`bundle.tar.gz`) from a Rego directory and optionally
pushes it to an OCI registry with one or more tags. Test files (`*_test.rego`)
are excluded so the production bundle stays lean.

## Prerequisites

OPA and ORAS are installed automatically when they aren't already on PATH. To
pin specific versions, run these earlier in the calling workflow and the action
will skip its own install steps:

- [`open-policy-agent/setup-opa`](https://github.com/open-policy-agent/setup-opa)
- [`oras-project/setup-oras`](https://github.com/oras-project/setup-oras)

Registry credentials are not installed by this action — when `push` is `'true'`,
the runner must already be authenticated to the target registry:

- [`docker/login-action`](https://github.com/docker/login-action) (or equivalent).

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `path` | yes |  | Path to the Rego directory to bundle. Resolves relative to the workspace. |
| `push` | no | `'true'` | Whether to push the built bundle to the registry. Set to `'false'` to build only — useful for PR validation where the push happens on merge. |
| `artifact-name` | conditional |  | Full OCI reference (without tag) to push to. Example: `ghcr.io/kartverket/accesserator/opa-bundle`. Required when `push` is `'true'`. |
| `additional-tags` | no | `''` | Extra tags to apply, one per line. `sha-<commit>` is always applied in addition to these. Ignored when `push` is `'false'`. |

## Outputs

| Name | Description |
|------|-------------|
| `bundle-path` | Path to the local bundle file (always `bundle.tar.gz`). |
| `digest` | Manifest digest of the pushed bundle (e.g. `sha256:...`). Empty when `push` is `'false'`. |
| `tags` | Comma-joined list of tags applied to the pushed bundle. Empty when `push` is `'false'`. |
| `image-ref` | Fully qualified `<artifact-name>@<digest>` reference. Use this for cosign signing or provenance attestation. Empty when `push` is `'false'`. |

## Behavior

- A missing `path` fails fast with a clear error.
- The bundle is built with `opa build -b <path> --ignore '*_test.rego' -o bundle.tar.gz`.
- After building, `tar -tzf bundle.tar.gz` lists the bundle contents in the job
  log so you can sanity-check what's included.
- When `push` is `'true'`, the manifest is tagged with `sha-<commit>` plus
  every entry of `additional-tags`. ORAS pushes a single manifest and applies
  all tags to it.
- Whitespace inside each `additional-tags` entry is stripped, so YAML block
  scalars with indentation work cleanly.
- A step summary is written with `if: always()` showing the image ref and tag
  list on a successful push, or a note when the bundle was built but not pushed
  (either because `push` was `'false'` or the push step failed).

## Example

Minimal usage, push to a SHA-only tag:

```yaml
- uses: actions/checkout@<sha>
- uses: docker/login-action@<sha>
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- uses: kartverket/actions/opa/build-push@<sha>
  with:
    path: opa
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
```

With additional tags on pushes to main:

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    path: opa
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
    additional-tags: |
      ${{ github.ref == 'refs/heads/main' && 'latest' || '' }}
```

Chaining with a cosign signing step:

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  id: build
  with:
    path: opa
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle

- run: cosign sign --yes --new-bundle-format ${{ steps.build.outputs.image-ref }}
```

Build-only (PR validation; push happens on merge):

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    path: opa
    push: ${{ github.event_name != 'pull_request' }}
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
```
