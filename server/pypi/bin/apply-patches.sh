#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

patch_dir="patches"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --patch-dir,patch_dir,,1,0,patch directory
# --source-dir,source_dir,,1,0,source directory
#]

. <(parse_command_line)

# apply patches

if [ -d "${patch_dir}" ]; then
  pushd "${source_dir}"

  for patch_file in ${patch_dir}/*; do
    if [ -f "${patch_file}" ]; then
      patch -p1 -i "${patch_file}"
    fi
  done

  popd
fi

echo "${0##*/} completed successfully."
