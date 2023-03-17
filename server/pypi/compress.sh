#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# clean and compress each folder individually

pushd "${DIST_DIR}"

for folder in *; do
  if [ -d "${folder}" ]; then
    rm -f "${folder}.zip"
    zip --quiet --recurse-paths "${folder}.zip" "${folder}" --exclude '*cp*-cp*iphone*.whl'
  fi
done

popd

echo "${0##*/} completed successfully."
