#!/usr/bin/env bash
set -euo pipefail

TAG=$(git describe --tags --abbrev=0)

git tag -f "$TAG" HEAD
git push --force origin "refs/tags/$TAG"

echo "Moved $TAG to $(git rev-parse --short HEAD)"