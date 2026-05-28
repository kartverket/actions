# OPA Build & Push

Builds an OPA bundle (`bundle.tar.gz`) from a Rego directory and pushes it to an
OCI registry with one or more tags. Test files (`*_test.rego`) are excluded so
the production bundle stays lean.

## Prerequisites

All three need to be set up earlier in the workflow:

- [`open-policy-agent/setup-opa`](https://github.com/open-policy-agent/setup-opa) — to run `opa build`.
- [`oras-project/setup-oras`](https://github.com/oras-project/setup-oras) — to push the bundle as an OCI artifact.
- [`docker/login-action`](https://github.com/docker/login-action) (or equivalent) — to authenticate to the target registry.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `rego-path` | yes |  | Path to the Rego directory to bundle. Resolves relative to the workspace. |
| `push` | no | `'true'` | If `'true'`, pushes the built bundle to the registry. Set to `'false'` to build only — useful for PR validation where the push happens on merge. |
| `artifact-name` | conditional |  | Full OCI reference (without tag) to push to. Example: `ghcr.io/kartverket/accesserator/opa-bundle`. Required when `push` is `'true'`. |
| `additional-tags` | no | `''` | Extra tags to apply, one per line. `sha-<commit>` is always applied in addition to these. Ignored when `push` is `'false'`. |
| `list-contents` | no | `'true'` | If `'true'`, runs `tar -tzf bundle.tar.gz` after the build so contents appear in the job log. |

## Outputs

| Name | Description |
|------|-------------|
| `bundle-path` | Path to the local bundle file (always `bundle.tar.gz`). |
| `digest` | Manifest digest of the pushed bundle (e.g. `sha256:...`). Empty when `push` is `'false'`. |
| `tags` | Comma-joined list of tags applied to the pushed bundle. Empty when `push` is `'false'`. |
| `image-ref` | Fully qualified `<artifact-name>@<digest>` reference. Use this for cosign signing or provenance attestation. Empty when `push` is `'false'`. |

## Behavior

- A missing `rego-path` fails fast with a clear error.
- The bundle is built with `opa build -b <rego-path> --ignore '*_test.rego' -o bundle.tar.gz`.
- The pushed manifest gets tagged with `sha-<commit>` plus every entry of
  `additional-tags`. ORAS pushes a single manifest and applies all tags to it.
- Whitespace inside each `additional-tags` entry is stripped, so YAML block
  scalars with indentation work cleanly.
- A step summary is written with `if: always()` showing the image ref and tags
  on a successful push, or a note that the bundle was built but not pushed
  otherwise. Visible under "Summary" in the Actions run UI.

## Example

Minimal usage, push to a SHA-only tag:

```yaml
- uses: open-policy-agent/setup-opa@<sha>
- uses: oras-project/setup-oras@<sha>
- uses: docker/login-action@<sha>
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- uses: kartverket/actions/opa/build-push@<sha>
  with:
    rego-path: policies
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
```

With additional tags on pushes to main:

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    rego-path: policies
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
    additional-tags: |
      ${{ github.ref == 'refs/heads/main' && 'latest' || '' }}
```

Chaining with a cosign signing step:

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  id: build
  with:
    rego-path: policies
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle

- run: cosign sign --yes --new-bundle-format ${{ steps.build.outputs.image-ref }}
```

Build-only (PR validation; the push happens on merge):

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    rego-path: policies
    push: ${{ github.event_name != 'pull_request' }}
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
```
