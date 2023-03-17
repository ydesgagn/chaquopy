#!/usr/bin/env bash

export CONDA_ENV="beeware"
export DIST_DIR="dist"
export PYTHON_VERSIONS="3.8 3.9 3.10 3.11"
export LOGS="logs"
export PACKAGES_DIR="packages"
TOOLCHAINS="$(pwd)/support"
export TOOLCHAINS

parse_command_line()
{
  local append argument default_value help_text line required variable_name
  printf "# default values\n\n"

  while read -r line; do
    IFS=, read -r argument variable_name default_value required append help_text <<< "${line}"

    if [ "${default_value}" != "-1" ]; then
      printf "%s=\"%s\"\n" "${variable_name}" "${default_value}"
    fi
  done < <(awk '/^#\[/,/^#\]/ { print }' <"${0}" | grep -v '\[' | grep -v '\]' | tr -d '#')

  printf "\n# parse command line\n\npositional=()\n\n"
  printf "while [[ \$# -gt 0 ]]; do\n"
  printf "  key=\"\${1}\"\n\n"
  printf "  case \"\${key}\" in\n"
  printf "  --help)\n"
  printf "  echo \"Usage: \${0##*/} options\n"
  printf "\n    options\n"

  while read -r line; do
    IFS=, read -r argument variable_name default_value required append help_text <<< "${line}"
    printf "            %s %s\n" "${argument}" "${help_text}"
  done < <(awk '/^#\[/,/^#\]/ { print }' <"${0}" | grep -v '\[' | grep -v '\]' | tr -d '#')

  printf "\"\n    exit 0\n    ;;\n\n"

  while read -r line; do
    IFS=, read -r argument variable_name default_value required append help_text <<< "${line}"

    if [ "${append}" == "1" ]; then
      printf "  %s)\n    %s=\"\${%s} %s \${2}\"\n    shift\n    shift\n    ;;\n\n" "${argument}" "${variable_name}" "${variable_name}" "${argument}"
    else
      printf "  %s)\n    %s=\"\${2}\"\n    shift\n    shift\n    ;;\n\n" "${argument}" "${variable_name}"
    fi
  done < <(awk '/^#\[/,/^#\]/ { print }' <"${0}" | grep -v '\[' | grep -v '\]' | tr -d '#')

  printf "  *)\n    positional+=(\"\${1}\")\n    shift\n    ;;\n  esac\ndone\n\nset -- \"\${positional[@]}\"\n\n"

  while read -r line; do
    IFS=, read -r argument variable_name default_value required append help_text <<< "${line}"

    if [ "${required}" == "1" ]; then
      printf "if [ -z \"\${%s}\" ]; then\n  echo \"Error: %s required !\"\n  exit 1\nfi\n\n" "${variable_name}" "${argument}"
    fi
  done < <(awk '/^#\[/,/^#\]/ { print }' <"${0}" | grep -v '\[' | grep -v '\]' | tr -d '#')
}