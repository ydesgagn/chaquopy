#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

options=""

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --package,options,-1,0,1,package
# --year,options,-1,0,1,year
#]

. <(parse_command_line)

# build packages for all python versions

rm -f "${LOGS}/success.log" "${LOGS}/fail.log"
touch "${LOGS}/success.log" "${LOGS}/fail.log"
eval "$(command conda 'shell.bash' 'hook')"

for python_version in ${PYTHON_VERSIONS}; do
  conda activate "${CONDA_ENV}-${python_version}"
  # shellcheck disable=SC2086
  ./make.sh ${options}
done

echo "${0##*/} completed successfully."
