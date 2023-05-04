#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

# TODO remove cmake and fallback on homebrew
cmake_version="3.26.0-rc1"
declare -A python_exact_versions
python_exact_versions["3.8"]="3.8.16"
python_exact_versions["3.9"]="3.9.16"
python_exact_versions["3.10"]="3.10.9"
python_exact_versions["3.11"]="3.11.0"

# init conda and clean toolchains

eval "$(command conda 'shell.bash' 'hook')"
conda activate base
rm -rf "${TOOLCHAINS}"

# install cmake

# TODO remove cmake and fallback on homebrew
curl --silent --location "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-macos-universal.tar.gz" --output cmake.tar.gz
mkdir -p "${TOOLCHAINS}"
tar -xzf cmake.tar.gz --directory "${TOOLCHAINS}"
mv "${TOOLCHAINS}/cmake-${cmake_version}"*/CMake.app "${TOOLCHAINS}"
rm -rf "${TOOLCHAINS}/cmake-${cmake_version}"* cmake.tar.gz

# setup clean conda environments and toolchains for each Python versions

for python_version in ${PYTHON_VERSIONS}; do
  rm -rf "$(conda info | grep 'envs directories' | awk -F ':' '{ print $2 }' | sed -e 's/^[[:space:]]*//')/${CONDA_ENV:?}-${python_version}"
  conda create -y --name "${CONDA_ENV}-${python_version}" "python==${python_exact_versions[${python_version}]}"
  conda activate "${CONDA_ENV}-${python_version}"
  pip3 install -r requirements.txt
  curl --silent --location "$(curl --silent -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" --location https://api.github.com/repos/beeware/Python-Apple-support/releases | grep browser_download_url | grep iOS | grep "${python_version}" | head -1 | awk '{ print $2 }' | tr -d '"')" --output "python-apple-support-${python_version}.tar.gz"
  mkdir -p "${TOOLCHAINS}/${python_version}" "${LOGS}/${python_version}"
  tar -xzf "python-apple-support-${python_version}.tar.gz" --directory "${TOOLCHAINS}/${python_version}"
  rm -rf "python-apple-support-${python_version}.tar.gz" "${LOGS:?}/${python_version:?}"/*
done

# setup docker for fortran/flang

if ! docker info &>/dev/null; then
  echo "Docker daemon not running!"
  exit 1
fi

export DOCKER_DEFAULT_PLATFORM=linux/amd64
# shellcheck disable=SC2048,SC2086
DOCKER_BUILDKIT=1 docker build -t flang --compress . $*
docker stop flang &>/dev/null || true
docker rm flang &>/dev/null || true
docker run -d --name flang -v "$(pwd)/share:/root/host" -v /Users:/Users -v /var/folders:/var/folders -it flang

echo "${0##*/} completed successfully."
