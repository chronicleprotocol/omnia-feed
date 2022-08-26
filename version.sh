#!/usr/bin/env bash
set -xeuo pipefail

# bump to next minor
_VERSION=$(semver -i minor "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump to next patch
_VERSION=$(semver -i "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# bump RC version
_VERSION=$(semver -i prerelease --preid rc "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version

# Describe change in a commit
git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version

# Tag version
git tag "v$(head -1 ./version | tr -d '\n')"

# Push to origin
git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"


_VERSION=$(semver -i "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"

# dev version bump
_VERSION=$(semver -i prerelease --preid dev "$(head -1 ./version | tr -d '\n')") && tee <<<"$_VERSION" ./version \
&& git commit -m "Bump version to 'v$(head -1 ./version | tr -d '\n')'" ./version \
&& git tag "v$(head -1 ./version | tr -d '\n')" \
&& git push --atomic origin "$(git rev-parse --abbrev-ref HEAD)" "v$(head -1 ./version | tr -d '\n')"
