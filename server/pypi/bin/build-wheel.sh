#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

patch_dir="patches"
prefix_dir="prefix"
requirements_dir="requirements"
source_dir="src"
wheel_file="WHEEL"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --abi-name,abi_name,,1,0,abi name
# --architecture,architecture,,1,0,architecture
# --build-number,build_number,,0,0,package build number (optional; overrides version in meta.yaml)
# --cflags,cflags,,0,0,cflags
# --last-wheel,last_wheel,,1,0,last wheel to build (also build the fat wheel)
# --ldflags,ldflags,,0,0,ldflags
# --os,os,,1,0,operating system to build
# --package,package,,1,0,package
# --python,python,,1,0,python version
# --sdk,sdk,,1,0,sdk
# --slice,slice,,1,0,slice
# --tool-prefix,tool_prefix,,1,0,tool prefix
# --toolchain,toolchain,,1,0,path to toolchain
# --version,version,,0,0,package version (optional; overrides version in meta.yaml)
#]

. <(parse_command_line)

# get api level

api_level=$(grep Min "${toolchain}/${python}/VERSIONS" | awk '{ print $4 }')

if [ -z "${api_level}" ]; then
  echo "Error: cannot read api level from ${toolchain}/${python}/VERSIONS !"
  exit 1
fi

# check package structure is available

package_dir="$(pwd)/${PACKAGES_DIR}/${package}"
meta_file="${package_dir}/meta.yaml"

if ! [ -d "${package_dir}" ]; then
  echo "Error: directory ${package_dir} not found !"
  exit 1
fi

if ! [ -f "${meta_file}" ]; then
  echo "Error: file ${meta_file} not found !"
  exit 1
fi

# read missing values from meta.yaml

package_name="$(yq '.package.name' "${meta_file}")"

if [ "${package_name}" == "null" ]; then
  echo "Error: package name not found in ${meta_file} !"
  exit 1
fi

if [ -z "${build_number}" ]; then
  build_number="$(yq '.build.number' "${meta_file}")"

  if [ "${build_number}" == "null" ]; then
    build_number="0"
  fi
fi

if [ -z "${version}" ]; then
  version="$(yq '.package.version' "${meta_file}")"

  if [ "${version}" == "null" ]; then
    echo "Error: package version not found in ${meta_file} !"
    exit 1
  fi
fi

compat_tag="${os,,}_${api_level//./_}_${abi_name}"
package_needs_python="$(yq '.source' "${meta_file}")"

if [ "${package_needs_python}" == "null" ]; then
  package_needs_python="1"
  package_compat_tag="cp${python/./}-cp${python/./}-${compat_tag}"
else
  package_needs_python="0"
  package_compat_tag="py3-none-${compat_tag}"
fi

# create clean directories

rm -rf "${package_dir}/build/${version}/${package_compat_tag}"
mkdir -p "${package_dir}/build/${version}/${package_compat_tag}"

# install requirements

if [ "$(yq '.requirements.host' "${meta_file}")" == "null" ]; then
  dependencies=null
else
  dependencies="$(yq '.requirements.host.[]' "${meta_file}" | tr '\n' ' ')"
fi

install-requirements.sh --dependencies "${dependencies}" --dependencies-dir "${package_dir}/build/${version}/${package_compat_tag}/${requirements_dir}" --requirements "$(pwd)/${PACKAGES_DIR}/${package}/requirements.in"

# unpack source

unpack-source.sh --directory "${package_dir}/build/${version}/${package_compat_tag}" --git-rev "$(yq '.source.git_rev' "${meta_file}")" --git-url "$(yq '.source.git_url' "${meta_file}")" --needs-python "${package_needs_python}" --package "${package}" --source-dir "${package_dir}/build/${version}/${package_compat_tag}/${source_dir}" --url "$(yq '.source.url' "${meta_file}")" --version "${version}"

# apply patches

apply-patches.sh --patch-dir "${package_dir}/${patch_dir}" --source-dir "${package_dir}/build/${version}/${package_compat_tag}/${source_dir}"

# build package

build-package.sh --abi-name "${abi_name}" --api-level "${api_level}" --architecture "${architecture}" --build-number "${build_number}" --cflags "${cflags}" --compat-tag "${package_compat_tag}" --dependencies-dir "${package_dir}/build/${version}/${package_compat_tag}/${requirements_dir}" --directory "${package_dir}/build/${version}/${package_compat_tag}" --ldflags "${ldflags}" --os "${os}" --package "${package}" --prefix-dir "${package_dir}/build/${version}/${package_compat_tag}/${prefix_dir}" --python "${python}" --recipe-dir "${package_dir}" --sdk "${sdk}" --slice "${slice}" --source-dir "${package_dir}/build/${version}/${package_compat_tag}/${source_dir}" --tool-prefix "${tool_prefix}" --toolchain "${toolchain}" --version "${version}"

# build fat wheel

if [ "${last_wheel}" == "1" ]; then
  normalize_name_pypi="$(echo "${package}" | sed -E 's/[-_.]+/-/g' | tr '[:upper:]' '[:lower:]')"
  fat_wheel_dir="${package_dir}/build/${version}"

  if [ "${package_needs_python}" == "1" ]; then
    fat_compat_tag="cp${python/./}-cp${python/./}-${os,,}_${api_level//./_}"
  else
    fat_compat_tag="py3-none-${os,,}_${api_level//./_}"
  fi

  rm -rf "${fat_wheel_dir:?}/${fat_compat_tag:?}"
  mkdir -p "${DIST_DIR}/${normalize_name_pypi}" "${fat_wheel_dir}/${fat_compat_tag}"
  wheel_folders=($(ls "${package_dir}/build/${version}" | grep _iphone))

  for folder in "${wheel_folders[@]}"; do
    unzip -oqd "${fat_wheel_dir}/${fat_compat_tag}" "${package_dir}/build/${version}/${folder}/${source_dir}"/*.whl

    if [ -n "$(find "${fat_wheel_dir}/${folder}/${prefix_dir}" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
      unzip -oqd "${fat_wheel_dir}/${folder}/${prefix_dir}" "${package_dir}/build/${version}/${folder}/${source_dir}"/*.whl
    fi
  done

  {
    echo "Wheel-Version: 1.0"
    echo "Root-Is-Purelib: false"
    echo "Generator: build-wheel.sh"
    echo "Build: ${build_number}"
    echo "Tag: ${fat_compat_tag}"
  } > "${fat_wheel_dir}/${fat_compat_tag}"/*.dist-info/"${wheel_file}"

  pushd "${fat_wheel_dir}/${fat_compat_tag}"

  while read -r file; do
    fat_binaries=""

    for folder in "${wheel_folders[@]}"; do
      if [ -e "${fat_wheel_dir}/${folder}/${prefix_dir}/${file}" ]; then
        fat_binaries="${fat_binaries} ${fat_wheel_dir}/${folder}/${prefix_dir}/${file}"
      fi
    done

    if [ "$(echo ${fat_binaries} | wc -w)" -gt 2 ]; then
      fat_binaries="$(echo ${fat_binaries} | awk '{ print $1 " " $3 }')"
    fi

    if [ "$(echo ${fat_binaries} | tr '[:space:]' '[\n*]' | grep -c arm64)" -gt 1 ]; then
      fat_binaries="$(echo ${fat_binaries} | awk '{ print $1 }')"
    fi

    if [ "$(echo ${fat_binaries} | wc -w)" -ge 1 ]; then
      lipo -create -o "${fat_wheel_dir}/${fat_compat_tag}/${file}" ${fat_binaries}
    fi
  done < <(find -E . -regex '.*(\.a|\.la|\.so|\.dylib)$')

  popd

  wheel pack "${fat_wheel_dir}/${fat_compat_tag}" --dest-dir "${DIST_DIR}/${normalize_name_pypi}" --build-number "${build_number}"
fi

echo "${0##*/} completed successfully."