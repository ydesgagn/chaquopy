#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

license_file1="LICENSE"
license_file2="COPYING"
metadate_file="METADATA"
wheel_file="WHEEL"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --build-number,build_number,,1,0,package build number
# --compat-tag,compat_tag,,1,0,compat tag
# --package,package,,1,0,package
# --prefix-dir,prefix_dir,,1,0,prefix directory
# --source-dir,source_dir,,1,0,source directory
# --version,version,,1,0,package version
#]

. <(parse_command_line)


# create clean directories

package_normalize_name_wheel=$(echo "${package}" | sed 's/[^A-Za-z0-9.]/_/g')
package_name_version="${package_normalize_name_wheel}-${version}"
info_dir="${prefix_dir}/${package_name_version}.dist-info"
mkdir -p "${info_dir}"

{
  echo "Metadata-Version: 1.2"
  echo "Name: ${package}"
  echo "Version: ${version}"
  echo "Summary: "
  echo "Download-URL: "
} > "${info_dir}/${metadate_file}"

{
  echo "Wheel-Version: 1.0"
  echo "Root-Is-Purelib: false"
  echo "Generator: build-wheel.sh"
  echo "Build: ${build_number}"
  echo "Tag: ${compat_tag}"
} > "${info_dir}/${wheel_file}"

if [ -f "${source_dir}/${license_file1}" ]; then
  cp "${source_dir}/${license_file1}" "${info_dir}"
elif [ -f "${source_dir}/${license_file1}.md" ]; then
  cp "${source_dir}/${license_file1}.md" "${info_dir}/${license_file1}"
elif [ -f "${source_dir}/${license_file1}.txt" ]; then
  cp "${source_dir}/${license_file1}.txt" "${info_dir}/${license_file1}"
elif [ -f "${source_dir}/../../../../${license_file1}" ]; then
  cp "${source_dir}/../../../../${license_file1}" "${info_dir}/${license_file1}"
elif [ -f "${source_dir}/../../../../${license_file1}.md" ]; then
  cp "${source_dir}/../../../../${license_file1}.md" "${info_dir}/${license_file1}"
elif [ -f "${source_dir}/../../../../${license_file1}.txt" ]; then
  cp "${source_dir}/../../../../${license_file1}.txt" "${info_dir}/${license_file1}"
elif [ -f "${source_dir}/${license_file1}/${license_file1}" ]; then
  cp "${source_dir}/${license_file1}/${license_file1}" "${info_dir}"
elif [ -f "${source_dir}/${license_file2}" ]; then
  cp "${source_dir}/${license_file2}" "${info_dir}/${license_file1}"
else
  echo "Error: no license file found !"
  exit 1
fi

wheel pack "${prefix_dir}" --dest-dir "${source_dir}" --build-number "${build_number}"

echo "${0##*/} completed successfully."
