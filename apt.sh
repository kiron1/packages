#!/usr/bin/env bash
#
# https://unix.stackexchange.com/a/403489
# https://gist.github.com/aarroyoc/1a96b2f8b01fcf34221a
#

set -euo pipefail

# repos=(kiron1/proxydetox kiron1/bazel-compile-commands)
repos=(kiron1/proxydetox)
machines=(x86_64)

declare -A aptarch=( ["x86_64"]="amd64" )

suits=(focal jammy)

eval "$(apt-config -c apt-ftparchive.conf shell archive_dir Dir::ArchiveDir/d)"

mkdir -p "${archive_dir}/pool/main"

for r in "${repos[@]}"; do
  tag=$(gh release view -R "${r}" --json tagName --jq '.tagName')
  for s in "${suits[@]}"; do
    mkdir -p "${archive_dir}/pool/${s}/main"
    rm -f -- "${archive_dir}/pool/${s}/main"/*.deb
    for m in "${machines[@]}"; do
      printf 'Download %s %s\n' "${r}" "${tag}"
      gh release download -R "${r}" "${tag}" --dir "${archive_dir}/pool/${s}/main" --pattern "*-${m}-${s}.deb" --skip-existing
    done
    find "${archive_dir}/pool/${s}/main/" -name '*.deb' -exec dpkg-name {} +
  done
done

r=kiron1/bazel-compile-commands
tag=$(gh release view -R "${r}" --json tagName --jq '.tagName')
gh release download -R "${r}" "${tag}" --dir "${archive_dir}/pool/focal/main" --pattern "*.deb" --skip-existing

for s in "${suits[@]}"; do
  for m in "${machines[@]}"; do
    mkdir -p "${archive_dir}/dists/${s}/main/binary-${aptarch[${m}]}"
  done
  apt-ftparchive generate apt-ftparchive.conf
  apt-ftparchive "-c=${s}.conf" release "${archive_dir}/dists/${s}" > "${archive_dir}/dists/${s}/Release"
done
