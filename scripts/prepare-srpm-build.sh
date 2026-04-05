#!/usr/bin/env bash
# Usage: scripts/prepare-srpm-build.sh [<git_ref>]
# Prepares rpmbuild directory (sources + spec) and outputs: VERSION COMMIT_SHA FULL_VERSION
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/vcs-helper.sh

GIT_REF=${1:-HEAD}
VERSION=$(vcs_latest_tag | cut -d'-' -f1)
COMMIT_SHA=$(vcs_current_sha)
FULL_VERSION="${VERSION}-${COMMIT_SHA}"

mkdir -p rpmbuild/SOURCES rpmbuild/SRPMS rpmbuild/RPMS rpmbuild/SPECS
vcs_archive "$GIT_REF" "sklein-devbox-${VERSION}/" "rpmbuild/SOURCES/sklein-devbox-${VERSION}.tar.gz"
sed \
    -e "s/^Version:.*/Version:        ${VERSION}/" \
    -e "s/^%define fullver.*/%define fullver ${FULL_VERSION}/" \
    rpm/sklein-devbox.spec > rpmbuild/SPECS/sklein-devbox.spec

echo "${VERSION} ${COMMIT_SHA} ${FULL_VERSION}"
