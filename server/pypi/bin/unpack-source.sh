#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --directory,directory,,1,0,directory
# --git-rev,git_rev,,1,0,git revision
# --git-url,git_url,,1,0,git url
# --needs-python,needs_python,,1,0,needs python
# --package,package,,1,0,package
# --source-dir,source_dir,,1,0,source directory
# --url,url,,1,0,url
# --version,version,,1,0,version
#]

. <(parse_command_line)

# create clean directories

mkdir -p "${source_dir}"
pushd "${directory}"

# unpack source

if [ "${needs_python}" == "1" ]; then
  source_filename="$(curl -s "https://pypi.org/pypi/${package}/json" | jq --raw-output --arg version "${version}" '.releases[$version][] | select(.packagetype == "sdist") | .url')"
  curl --silent --location "${source_filename}" --output "${source_filename##*/}"
  source_filename="${source_filename##*/}"
elif [ "${url}" != "null" ] ;then
  source_filename="${url}"
  curl --silent --location "${source_filename}" --output "${source_filename##*/}"
  source_filename="${source_filename##*/}"
elif [ "${git_url}" != "null" ] ;then
  source_filename="${git_url}"
  git clone --recurse-submodules "${source_filename}" "${source_dir}"
  git -C "${source_dir}" checkout --detach "${git_rev}"
  git -C "${source_dir}" submodule update --init
  source_filename="null"
else
    echo "Error: cannot unpack source !"
    exit 1
fi

if [ "${source_filename}" != "null" ]; then
  tmp_dir=$(mktemp -d -t chaquopy)

  if [[ "${source_filename}" == *.zip ]]; then
    unzip -d "${tmp_dir}" -q "${source_filename}"
  elif [[ "${source_filename}" == *.tar ]] ;then
    tar --directory "${tmp_dir}" -xf "${source_filename}"
  elif [[ "${source_filename}" == *.tar.gz ]];then
    tar --directory "${tmp_dir}" -xzf "${source_filename}"
  else
      echo "Error: unknown filetype to decompress source !"
      exit 1
  fi

  mv "${tmp_dir}"/*/* "${source_dir}"
  rm -rf "${source_filename}" "${tmp_dir}"

  if [ -f  "${source_dir}/pyproject.toml" ]; then
    mv "${source_dir}/pyproject.toml" "${source_dir}/pyproject-chaquopy-disabled.toml"
  fi
fi

popd

echo "${0##*/} completed successfully."
