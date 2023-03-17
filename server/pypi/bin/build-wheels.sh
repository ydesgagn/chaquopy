#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

abis_file="abis.yaml"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --build-number,build_number,,0,0,build number (optional; overrides version in meta.yaml)
# --os,os,,1,0,operating system to build
# --package,package,,1,0,package
# --python,python,,1,0,python version
# --toolchain,toolchain,,1,0,path to toolchain
# --version,version,,0,0,package version (optional; overrides version in meta.yaml)
#]

. <(parse_command_line)

# set path to find the bin directory with our helper scripts

base_dir="$(pwd)"
export PATH="${base_dir}/bin:${PATH}"

# build package for all sdks and architectures

sdk_index_max=$(yq ".os[.${os}].[] | length" "${abis_file}")

if [ "${sdk_index_max}" == "null" ]; then
  echo "Error: os not found in ${abis_file} !"
  exit 1
fi

for ((sdk_index = 0; sdk_index < "${sdk_index_max}"; sdk_index++)); do
  # for each architecture

  architecture_index_max=$(yq ".os[.${os}].[][${sdk_index}].[] | length" "${abis_file}")

  if [ "${architecture_index_max}" == "null" ]; then
    echo "Error: sdks not found in ${abis_file} !"
    exit 1
  fi

  for ((architecture_index = 0; architecture_index < "${architecture_index_max}"; architecture_index++)); do
    architecture=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}] | keys | .[]" "${abis_file}")
    abi_name=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].name" "${abis_file}")
    tool_prefix=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].tool_prefix" "${abis_file}")
    cflags=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].cflags" "${abis_file}")
    ldflags=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].ldflags" "${abis_file}")
    sdk=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].sdk" "${abis_file}")
    slice=$(yq ".os[.${os}].[][${sdk_index}].[][${architecture_index}][].slice" "${abis_file}")

    if [ "${architecture}" == "null" ]; then
      echo "Error: architecture not found in ${abis_file} !"
      exit 1
    fi

    if [ "${abi_name}" == "null" ]; then
      echo "Error: sdks not found in ${abis_file} !"
      exit 1
    fi

    if [ "${tool_prefix}" == "null" ]; then
      echo "Error: tool prefix not found in ${abis_file} !"
      exit 1
    fi

    if [ "${cflags}" == "null" ]; then
      echo "Error: cflags not found in ${abis_file} !"
      exit 1
    fi

    if [ "${ldflags}" == "null" ]; then
      echo "Error: ldflags not found in ${abis_file} !"
      exit 1
    fi

    if [ "${sdk}" == "null" ]; then
      echo "Error: sdk not found in ${abis_file} !"
      exit 1
    fi

    if [ "${slice}" == "null" ]; then
      echo "Error: slice not found in ${abis_file} !"
      exit 1
    fi

    if [ "${sdk_index}" == "$((sdk_index_max- 1))" ] && [ "${architecture_index}" == "$((architecture_index_max-1))" ]; then
      last_wheel=1
    else
      last_wheel=0
    fi

    build-wheel.sh --abi-name "${abi_name}" --architecture "${architecture}" --build-number "${build_number}" --cflags "${cflags}" --last-wheel ${last_wheel} --ldflags "${ldflags}" --os "${os}" --package "${package}" --python "${python}" --sdk "${sdk}" --slice "${slice}" --tool-prefix "${tool_prefix}" --toolchain "${toolchain}" --version "${version}"
  done
done

echo "${0##*/} completed successfully."
