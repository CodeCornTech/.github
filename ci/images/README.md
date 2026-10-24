# Shared PHP/Node CI containers on DKR-01

Use five versioned images in GHCR:

- `ghcr.io/codecorntech/ci-php:8.1-node22-v1`
- `ghcr.io/codecorntech/ci-php:8.2-node22-v1`
- `ghcr.io/codecorntech/ci-php:8.3-node22-v1`
- `ghcr.io/codecorntech/ci-php:8.4-node22-v1`
- `ghcr.io/codecorntech/ci-php:8.1-node22-playwright1.62.1-v1`

These are proposed tags **not yet published**. Image inputs are official `php:<version>-cli-bookworm`, Node 22, Composer 2; Playwright installs Chromium once at image build time.

On DKR-01 run `bash ci/images/build.sh --dry-run`, then `--build`, then `--check`. Publish only when the check passes, with an authorized `docker login ghcr.io` using a `write:packages` token and `--publish`.

Private GHCR packages need explicit GitHub Actions access for *both* `CodeCornTech/barbagia-media-manager` and `fgirolami29/wp-life-helper`, or make the image public. Workflow `jobs.container` attempts to pull images; a locally built tag is not a published GHCR package. **Do not merge consumer workflows before image access is confirmed.**

The build command requires >=6 GiB free on /var/lib/docker and does not remove volumes, images or caches. With only 32 GiB, inspect `docker system df` after builds. Jobs must be trusted: membership in the Docker group is root-equivalent and different Unix accounts sharing the same Docker daemon do **not** isolate runner credentials. Do not add untrusted fork PRs. Do not mount Docker socket into PHP job containers.
