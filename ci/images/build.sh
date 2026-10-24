#!/bin/bash
# DKR-01: prepare four PHP/Node toolchains and one Playwright image.
# --dry-run (default), --build, --check, --publish (explicit).
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
mode="${1:---dry-run}"
[[ "$#" -le 1 ]] || exit 2
case "$mode" in --dry-run|--build|--check|--publish) ;; *) echo 'Usage: build.sh --dry-run|--build|--check|--publish' >&2; exit 2 ;; esac
base='ghcr.io/codecorntech/ci-php'
versions=(8.1 8.2 8.3 8.4)
browser_tag="${base}:8.1-node22-playwright1.62.1-v1"
if [[ "$mode" == --dry-run ]]; then
    echo 'NO CHANGES: would build/verify four PHP images + one Playwright image'
    for v in "${versions[@]}"; do echo "${base}:${v}-node22-v1"; done
    echo "$browser_tag"
    echo 'No Docker prune. Publish separate and explicit, requires GHCR login.'
    df -h /var/lib/docker 2>/dev/null || df -h /
    exit 0
fi
docker info >/dev/null || { echo 'ERROR: cannot access Docker daemon' >&2; exit 1; }
if [[ "$mode" == --build ]]; then
    free_kb="$(df -Pk /var/lib/docker | awk 'NR==2 {print $4}')"
    [[ "$free_kb" =~ ^[0-9]+$ && "$free_kb" -ge 6291456 ]] || { echo 'ERROR: less than 6GiB disk free' >&2; exit 1; }
    for v in "${versions[@]}"; do
        tag="${base}:${v}-node22-v1"
        docker buildx build --load --pull --progress=plain -f Dockerfile --build-arg "PHP_VERSION=$v" -t "$tag" .
    done
    docker buildx build --load --progress=plain -f Dockerfile.playwright \
        --build-arg "BASE_IMAGE=${base}:8.1-node22-v1" \
        --build-arg 'PLAYWRIGHT_VERSION=1.62.1' -t "$browser_tag" .
    echo 'Build finished; run --check before --publish.'
elif [[ "$mode" == --check ]]; then
    for v in "${versions[@]}"; do
        tag="${base}:${v}-node22-v1"
        docker image inspect "$tag" >/dev/null || { echo "MISSING: $tag"; exit 1; }
        major="${v%%.*}"; minor="${v#*.}"
        docker run --rm --pull=never --entrypoint sh "$tag" -ec \
            "php -r 'exit(PHP_MAJOR_VERSION===$major && PHP_MINOR_VERSION===$minor ? 0 : 1);' && php -m | grep -iq zip && node -e 'process.exit(process.versions.node.startsWith(\\\"22.\\\")?0:1)' && composer --version"
        echo "OK: $tag"
    done
    docker image inspect "$browser_tag" >/dev/null || { echo "MISSING: $browser_tag"; exit 1; }
    docker run --rm --pull=never --entrypoint sh "$browser_tag" -ec \
        'node -e '\''const p=require(process.env.PLAYWRIGHT_MODULE); if(!require("fs").existsSync(p.chromium.executablePath())) process.exit(1)'\''
    echo "OK: $browser_tag"
    docker system df
    echo 'CHECK PASSED'
else
    echo 'Requires existing docker login ghcr.io (write:packages).'
    read -r -p 'Type PUBLISH to upload all five images: ' confirm
    [[ "$confirm" == PUBLISH ]] || { echo 'Aborted'; exit 1; }
    for v in "${versions[@]}"; do
        tag="${base}:${v}-node22-v1"
        docker image inspect "$tag" >/dev/null
        docker push "$tag"
    done
    docker image inspect "$browser_tag" >/dev/null
    docker push "$browser_tag"
    echo 'Verify GHCR visibility/access from BOTH GitHub owners before CI migration.'
fi
