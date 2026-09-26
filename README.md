# yt-dlp-oci

Debian-based base image with `yt-dlp[default]`, its Python dependencies, and
Deno for JavaScript challenge handling. Python 3.14.7 is installed by mise
during the build; uv installs the hash-locked Python dependencies into
`/opt/venv`. Neither mise nor uv is shipped in the final image.

The image runs as non-root UID/GID 1000, starts in writable `/data`, and uses
`yt-dlp` as its entrypoint. `/opt/venv/bin` (including `python` and `yt-dlp`)
and `/usr/local/bin` (including `deno`) are on `PATH`.

```sh
just build-image
just smoke-image
# Download into the current directory:
docker run --rm -v "$PWD:/data" ghcr.io/acidghost/yt-dlp-oci:local 'https://example.com/video'
```

To use it as a base image, select a release tag (or pin the published image by
digest for reproducible builds):

```dockerfile
FROM ghcr.io/acidghost/yt-dlp-oci:2026.8.19-0
```

The [Test Image workflow](.github/workflows/test-image.yaml) can be run manually
from GitHub Actions to build and smoke-test the image without publishing it.
Image builds do not run in the regular CI workflow.

## Updating

`requirements.in` and the hashed `requirements.txt` are copied from
`yt-dlp-mcp`. After changing the input, regenerate the lockfile with
`just update-requirements` (requires the existing mise-managed uv), then build
and smoke-test the image. Keep the Python version in `.python-version`,
`Dockerfile`, and `justfile` in sync. Build-only Python and uv versions are
pinned in `Dockerfile`; `mise.toml` lists only tools used on the host.

## Release

The Git tag and image tag have the form `<yt-dlp-version>-<image-patch-number>`,
e.g. `2026.8.19-0`. The first release of a new yt-dlp version uses patch `0`;
subsequent releases for that version increment the highest patch found in local
tags and on `origin`. All modes require matching yt-dlp versions in
`requirements.in` and `requirements.txt`:

- `bash scripts/release.sh --next`: print the next tag without creating or
  pushing it. Requires a clean `main` branch and reads local tags and `origin`.
- `bash scripts/release.sh`: create an annotated tag for that next version and
  push it to `origin`, triggering publication. Requires a clean `main` branch;
  push your commits first.
- `bash scripts/release.sh --check <tag>`: validate the tag's yt-dlp version and
  patch-number format without accessing Git or changing anything. Used by the
  publish workflow.

The release modes query `origin` so a fresh clone won't reuse a published patch
number. A failed push leaves the local tag in place; push it with
`git push origin refs/tags/<tag>` after resolving the problem. The
[tag-triggered publish workflow](.github/workflows/publish-image.yaml) verifies
the version again, publishes `ghcr.io/acidghost/yt-dlp-oci:<tag>` for
linux/amd64 with provenance and an SBOM, then keyless-signs the image. No moving
`latest` tag is published.

To verify a published image:

```sh
cosign verify ghcr.io/acidghost/yt-dlp-oci:2026.8.19-0 \
  --certificate-identity-regexp 'https://github.com/acidghost/yt-dlp-oci/.github/workflows/publish-image.yaml@.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```
