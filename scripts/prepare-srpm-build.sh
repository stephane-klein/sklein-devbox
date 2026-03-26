#!/usr/bin/env bash
# Usage: scripts/prepare-srpm-build.sh [<git_ref>]
# Prepares rpmbuild directory (sources + spec) and outputs: VERSION COMMIT_SHA FULL_VERSION
set -euo pipefail

cd "$(dirname "$0")/.."

GIT_REF=${1:-HEAD}
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | cut -d'-' -f1)
COMMIT_SHA=$(git rev-parse --short HEAD)
FULL_VERSION="${VERSION}-${COMMIT_SHA}"

mkdir -p rpmbuild/SOURCES rpmbuild/SRPMS rpmbuild/RPMS rpmbuild/SPECS
git archive --format tar.gz \
    --prefix sklein-devbox-${VERSION}/ \
    --output rpmbuild/SOURCES/sklein-devbox-${VERSION}.tar.gz \
    "$GIT_REF"
sed \
    -e "s/^Version:.*/Version:        ${VERSION}/" \
    -e "s/^%define fullver.*/%define fullver ${FULL_VERSION}/" \
    rpm/sklein-devbox.spec > rpmbuild/SPECS/sklein-devbox.spec

echo "${VERSION} ${COMMIT_SHA} ${FULL_VERSION}"
