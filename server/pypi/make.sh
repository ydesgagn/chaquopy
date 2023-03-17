#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

packages="
    cffi \
    numpy \
    aiohttp \
    argon2-cffi \
    backports-zoneinfo \
    bcrypt \
    bitarray \
    brotli \
    cryptography \
    cymem \
    cytoolz \
    editdistance \
    ephem \
    frozenlist \
    gensim \
    greenlet \
    kiwisolver \
    lru-dict \
    matplotlib \
    multidict \
    murmurhash \
    netifaces \
    pandas \
    pillow \
    preshed \
    pycrypto \
    pycurl \
    pynacl \
    pysha3 \
    pywavelets \
    pyzbar \
    regex \
    ruamel-yaml-clib \
    scandir \
    spectrum \
    srsly \
    statsmodels \
    twisted \
    typed-ast \
    ujson \
    wordcloud \
    yarl \
    zstandard \
    "

# parse command line

#[ argument,variable_name,default_value,required,help_text
# --package,packages,-1,0,0,package
# --year,year,2019,0,0,year
#]

. <(parse_command_line)

# set path to find the bin directory with our helper scripts

base_dir="$(pwd)"
export PATH="${base_dir}/bin:${PATH}"

# build packages

touch "${LOGS}/success.log" "${LOGS}/fail.log"
python_version=$(python --version | awk '{ print $2 }' | awk -F '.' '{ print $1 "." $2 }')

for package in ${packages}; do
  package_versions="$(versions.sh --year "${year}" --package "${package}" --python "${python_version}")"
  printf "\n### Attempting package %s with versions: %s ###\n" "${package}" "${package_versions}"

  for package_version in ${package_versions}; do
    # edit package dependencies
    # FIXME: remove the for loop with the sed below
    # FIXME: short term workaround until we can find a better way to deal with dependencies
    # FIXME: without editing the meta.yaml file and without generating a lot of manual maintenance

    # shellcheck disable=SC2043
    for dependency in numpy; do
      if grep "${dependency}" "packages/${package}/meta.yaml" &>/dev/null; then
        # shellcheck disable=SC2012
        sed -i '' "s/- ${dependency}.*/- ${dependency} $(ls -1 "${DIST_DIR}/${dependency}"/*"${python_version/./}"* | head -1 | awk -F '-' '{ print $2 }')/g" "packages/${package}/meta.yaml"
      fi
    done

    printf "\n\n*** Building package %s version %s for Python %s ***\n\n" "${package}" "${package_version}" "${python_version}"
    build-wheels.sh --toolchain "${TOOLCHAINS}" --python "${python_version}" --os iOS --package "${package}" --package-version "${package_version}" 2>&1 | tee "${LOGS}/${python_version}/${package}.log"

    # shellcheck disable=SC2010
    if [ "$(ls "${DIST_DIR}/${package}" | grep "cp${python_version/./}" | grep -c "${package_version}")" -ge "4" ]; then
      echo "${package}-${package_version} with Python ${python_version}" >>"${LOGS}/success.log"
    else
      echo "${package}=${package_version} with Python ${python_version}" >>"${LOGS}/fail.log"
    fi
  done
done

# print build results

echo ""
echo "Packages built successfully:"
cat "${LOGS}/success.log"
echo ""
echo "Packages with errors:"
cat "${LOGS}/fail.log"
echo ""

echo "${0##*/} completed successfully."
