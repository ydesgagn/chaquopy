#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
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

echo "${0##*/} completed successfully."
