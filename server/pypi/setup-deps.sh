#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

dependencies=" \
  chaquopy-curl \
  chaquopy-freetype \
  chaquopy-libiconv \
  chaquopy-libjpeg \
  chaquopy-libogg \
  chaquopy-libpng \
  chaquopy-libxml2 \
  chaquopy-openblas \
  chaquopy-ta-lib \
  chaquopy-zbar \
  "
python_apple_support="Python-Apple-support"
python_version="3.10"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --package,dependencies,-1,0,0,package
# --build-dependencies,build_dependencies,1,0,0,build python dependencies
#]

. <(parse_command_line)

# set path to find the bin directory with our helper scripts

base_dir="$(pwd)"
export PATH="${base_dir}/bin:${PATH}"

# build Python dependencies

if [ "${build_dependencies}" == "1" ]; then
  pushd "${TOOLCHAINS}"

  if ! [ -d "${python_apple_support}" ]; then
    git clone -b "${python_version}" https://github.com/beeware/Python-Apple-support.git
  fi

  pushd "${python_apple_support}"
  make
  make libFFI-wheels
  make OpenSSL-wheels
  make BZip2-wheels
  make XZ-wheels
  popd
  popd

  rm -rf "${DIST_DIR}/bzip2" "${DIST_DIR}/libffi" "${DIST_DIR}/openssl" "${DIST_DIR}/xz" "${LOGS}/deps"
  mkdir -p "${DIST_DIR}" "${LOGS}/deps"
  mv -f "${TOOLCHAINS}/${python_apple_support}/wheels/dist"/* "${DIST_DIR}"
fi

# build chaquopy dependencies

rm -f "${LOGS}/deps_success.log" "${LOGS}/deps_fail.log"
touch "${LOGS}/deps_success.log" "${LOGS}/deps_fail.log"

for dependency in ${dependencies}; do
  printf "\n\n*** Building dependency %s ***\n\n" "${dependency}"
  build-wheels.sh --toolchain "${TOOLCHAINS}" --python "${python_version}" --os iOS --package "${dependency}" 2>&1 | tee "${LOGS}/deps/${dependency}.log"

  # shellcheck disable=SC2010
  if [ "$(ls "${DIST_DIR}/${dependency}" | grep -c py3)" -ge "1" ]; then
    echo "${dependency}" >>"${LOGS}/deps_success.log"
  else
    echo "${dependency}" >>"${LOGS}/deps_fail.log"
  fi
done

# print build results

echo ""
echo "Packages built successfully:"
cat "${LOGS}/deps_success.log"
echo ""
echo "Packages with errors:"
cat "${LOGS}/deps_fail.log"
echo ""

echo "${0##*/} completed successfully."
