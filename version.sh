#!/usr/bin/env bash
set -xeuo pipefail

# bump to next minor
_VERSION=$(semver -i minor "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump to next patch
_VERSION=$(semver -i "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump RC version
_VERSION=$(semver -i preminor --preid pre "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# Describe change in a commit
git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version

# Tag version
git tag "v$(head -1 ./version | tr -d '\n')"

# Push to origin
git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"

# RC version bump & tag & push
_VERSION=$(semver -i prerelease --preid rc "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"

# PATCH version bump & tag & push
_VERSION=$(semver -i "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"

# BUMP DEV
_VERSION=$(semver -i prerelease --preid dev "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version ./nix/sources.json \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)"

# NEW MINOR DEV - wen new feature
_VERSION=$(semver -i preminor --preid dev "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version ./nix/sources.json \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)"

# -i --increment [<level>]
#        Increment a version by the specified level.  Level can
#        be one of: major, minor, patch, premajor, preminor,
#        prepatch, or prerelease.  Default level is 'patch'.
#        Only one version may be specified.
#
# --preid <identifier>
#        Identifier to be used to prefix premajor, preminor,
#        prepatch or prerelease version increments.