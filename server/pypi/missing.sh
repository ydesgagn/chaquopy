#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# check for missing packages

for package in ./packages/*; do
  if ! [ -d "${DIST_DIR}/$(basename "${package}")" ]; then
    echo "- $(basename "${package}"): all"
  else
    for python_version in ${PYTHON_VERSIONS}; do
      # shellcheck disable=SC2010
      if ! [ "$(ls "${DIST_DIR}/$(basename "${package}")" | grep -c "cp${python_version/./}")" -ge "4" ]; then
        echo "- $(basename "${package}"): ${python_version}"
      fi
    done
  fi
done

echo "${0##*/} completed successfully."
