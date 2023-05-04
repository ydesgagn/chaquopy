#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --dependencies,dependencies,,1,0,dependencies
# --dependencies-dir,dependencies_dir,,1,0,directory
# --requirements,requirements_file,,1,0,requirements file
#]

. <(parse_command_line)

# install pip requirements

if [ -f "${requirements_file}" ]; then
  rm -rf "${requirements_file/.in/.txt}"
  pip-compile --resolver=backtracking "${requirements_file}"
  pip3 install -r "${requirements_file/.in/.txt}"
  rm -rf "${requirements_file/.in/.txt}"
fi

# install dependencies

mkdir -p "${dependencies_dir}"

for dependency in ${dependencies}; do
  if [ "${dependency}" == "null" ]; then
    continue
  fi

  unzip -oqd "${dependencies_dir}" "${DIST_DIR}/${dependency}"/*.whl
done

rm -rf "${dependencies_dir}"/*.dist-info

echo "${0##*/} completed successfully."
