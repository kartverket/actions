# OPA Build & Push

Builds an OPA bundle (`bundle.tar.gz`) from a Rego directory and optionally
pushes it to an OCI registry. The bundle is always tagged with
`sha256-<content-hash>`, where `<content-hash>` is `sha256sum bundle.tar.gz`.
`additional-tags` appends to that. Test files (`*_test.rego`) are excluded so
the production bundle stays lean.

When a bundle with the same content sha already exists in the registry, the
action skips the push and applies `additional-tags` to the existing manifest
via `oras tag`. This avoids creating duplicate manifests/signatures/provenance
attestations for identical content.

> **Determinism caveat:** the cache only hits when `opa build` produces
> byte-identical output across runs. By default it does not — gzip embeds an
> mtime and tar entry ordering can vary. The action still works correctly
> without deterministic builds; the cache simply misses more often. For
> reproducible builds, post-process the tarball (e.g. `gunzip` + `gzip -n`,
> repack tar with `--sort=name --mtime=...`) before the action runs.

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
| `additional-tags` | no | `''` | Comma-separated list of extra tags to apply (e.g. `latest,v1`). `sha256-<content-hash>` is always applied in addition to these. Ignored when `push` is `'false'`. |

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
- When `push` is `'true'`, the manifest is tagged with
  `sha256-<content-hash>` (where `<content-hash>` = `sha256sum bundle.tar.gz`)
  plus every entry of `additional-tags`.
  - **First push for this content:** ORAS pushes a single manifest with every
    tag in one call (`...:tag1,tag2,tag3`).
  - **Repeat push of identical content** (i.e.
    `<artifact-name>:sha256-<content-hash>` already exists): the action skips
    re-pushing and uses `oras tag` to apply each extra tag to the existing
    manifest. This keeps re-runs cheap and avoids piling up duplicate manifests
    / signatures / provenance attestations for identical content.
- `additional-tags` is split on commas. Whitespace around each tag is stripped,
  so `'latest, v1, stable'` and `'latest,v1,stable'` produce the same result.
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
    additional-tags: ${{ github.ref == 'refs/heads/main' && 'latest' || '' }}
```

Or multiple tags at once:

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    path: opa
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
    additional-tags: latest,v1,stable
```

Build-only (PR validation; push happens on merge):

```yaml
- uses: kartverket/actions/opa/build-push@<sha>
  with:
    path: opa
    push: ${{ github.event_name != 'pull_request' }}
    artifact-name: ghcr.io/${{ github.repository }}/opa-bundle
```
