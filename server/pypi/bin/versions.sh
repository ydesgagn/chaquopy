#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --package,package,,1,0,package
# --python,python,,1,0,python
# --year,year,,1,0,year
#]

. <(parse_command_line)

# check available versions on pypi for macos

url="https://pypi.org/pypi/${package}/json"
versions=()

while IFS= read -r json; do
  version=$(echo "${json}" | jq --raw-output .version)
  upload_time=$(echo "${json}" | jq --raw-output .upload_time | cut -d '-' -f1)

  if [[ ${upload_time} -ge ${year} ]] && [[ ${version} =~ ^[\.0-9]+$ ]]; then
    versions+=("${version}")
  fi
done < <(curl -sSL "${url}" | jq --compact-output ".releases | keys[] as \$version | .[\$version][] | select(length > 0) | select(.python_version == \"cp${python/./}\") | select(.packagetype == \"bdist_wheel\") | select(.filename | contains(\"-macosx_\")) | {version: \$version, upload_time: .upload_time}")

printf "%s\n" "${versions[@]}" | sort --unique
