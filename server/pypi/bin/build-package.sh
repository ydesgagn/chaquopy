#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh

# default values and settings

additional_includes=""
additional_libraries=""
build_file="build.sh"
build_script="chaquopy.sh"
post_build_file="post_build.sh"
pre_build_file="pre_build.sh"

# parse command line

#[ argument,variable_name,default_value,required,append,help_text
# --abi-name,abi_name,,1,0,abi name
# --api-level,api_level,,1,0,api level
# --architecture,architecture,,1,0,architecture
# --build-number,build_number,,1,0,package build number
# --cflags,cflags,,0,0,cflags
# --compat-tag,compat_tag,,0,0,compat tag
# --dependencies-dir,dependencies_dir,,1,0,directory
# --directory,directory,,1,0,directory
# --ldflags,ldflags,,0,0,ldflags
# --os,os,,1,0,operating system to build
# --package,package,,1,0,package
# --prefix-dir,prefix_dir,,1,0,prefix directory
# --python,python,,1,0,python version
# --recipe-dir,recipe_dir,,1,0,recipe directory
# --sdk,sdk,,1,0,sdk
# --slice,slice,,1,0,slice
# --source-dir,source_dir,,1,0,source directory
# --tool-prefix,tool_prefix,,1,0,tool prefix
# --toolchain,toolchain,,1,0,path to toolchain
# --version,version,,1,0,package version
#]

. <(parse_command_line)

# detect include and libs directories in dependencies

for dependency in ${dependencies_dir}/*; do
  if [ -d "${dependency}/include" ]; then
    additional_includes="${additional_includes} -I${dependency}/include"
  fi

  if [ -d "${dependency}/lib" ]; then
    additional_libraries="${additional_libraries} -I${dependency}/lib"
  fi
done

# generate sandboxed build script

{
  echo "#!/usr/bin/env bash"
  echo "set -e"
  echo ""
  echo "export PATH=\"$(pwd)/bin:$(dirname $(which python)):/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:$(dirname $(which brew))\""
  echo "export PYTHONPATH=\"$(pwd)/env/lib/python:${directory}/requirements\""
  echo "export CHAQUOPY_ABI=\"${abi_name}\""
  echo "export CHAQUOPY_PYTHON=\"${python}\""
  echo "export CHAQUOPY_TRIPLET=\"${tool_prefix}\""
  echo "export CPU_COUNT=\"$(sysctl -n hw.ncpu)\""
  echo "export PKG_BUILDNUM=\"${build_number}\""
  echo "export PKG_NAME=\"${package}\""
  echo "export PKG_VERSION=\"${version}\""
  echo "export RECIPE_DIR=\"${recipe_dir}\""
  echo "export SRC_DIR=\"${directory}/${SRC_DIR}\""
  echo "export CROSS_COMPILE_PLATFORM=\"${os,,}\""
  echo "export CROSS_COMPILE_PLATFORM_TAG=\"${os}_${api_level}_${abi_name}\""
  echo "export CROSS_COMPILE_PREFIX=\"${toolchain}/${python}/Python.xcframework/${slice}\""
  echo "export CROSS_COMPILE_IMPLEMENTATION=\"${abi_name}\""
  echo "export CROSS_COMPILE_SDK_ROOT=\"$(xcrun --show-sdk-path --sdk ${sdk})\""
  echo "export CROSS_COMPILE_TOOLCHAIN_SLICE=\"${slice}\""
  echo "export CROSS_COMPILE_SYSCONFIGDATA=\"${toolchain}/${python}/python-stdlib/_sysconfigdata__${os,,}_${abi_name}.py\""
  echo "export AR='xcrun --sdk ${sdk} ar'"
  echo "export ARFLAGS='rcs'"
  echo "export BLDSHARED=\"xcrun --sdk ${sdk} clang -target ${tool_prefix} -bundle -undefined dynamic_lookup -isysroot $(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level}\""
  echo "export CFLAGS=\"${cflags} ${additional_includes} -Wno-unused-result -Wsign-compare -Wunreachable-code -DNDEBUG -g -fwrapv -O3 -Wall --sysroot=$(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level} -idirafter ${toolchain}/${python}/Python.xcframework/${slice}/Headers\""
  echo "export CC=\"xcrun --sdk ${sdk} clang -target ${tool_prefix}\""
  echo "export CXX=\"xcrun --sdk ${sdk} clang -target ${tool_prefix}\""
  echo "export CONFIGURE_CFLAGS=\"${cflags} --sysroot=$(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level}\""
  echo "export CONFIGURE_LDFLAGS=\"${ldflags} -isysroot $(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level}\""
  echo "export LDFLAGS=\"${ldflags} ${additional_libraries} -isysroot $(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level}\""
  echo "export LDSHARED=\"xcrun --sdk ${sdk} clang -target ${tool_prefix} -bundle -undefined dynamic_lookup -isysroot $(xcrun --show-sdk-path --sdk ${sdk}) -mios-version-min=${api_level}\""
  echo "export PREFIX=\"${prefix_dir}/opt\""
  echo ""
} > "${directory}/${build_script}"

# add any platform specific code

if [ -f "${recipe_dir}/${abi_name}.sh" ]; then
  {
    cat "${recipe_dir}/${abi_name}.sh"
    echo ""
  } >> "${directory}/${build_script}"
fi

# add pre build steps

if [ -f "${recipe_dir}/${pre_build_file}" ]; then
  {
    cat "${recipe_dir}/${pre_build_file}"
    echo ""
  } >> "${directory}/${build_script}"
fi

# add custom build script or fallback on pip

if [ -f "${recipe_dir}/${build_file}" ]; then
  cat "${recipe_dir}/${build_file}" >> "${directory}/${build_script}"
else
  echo "pip wheel --no-deps --no-clean --build-option --keep-temp -e ." >> "${directory}/${build_script}"
fi

{
  echo ""
  echo "echo \"${0##*/} completed successfully.\""
} >> "${directory}/${build_script}"

# add post build steps

if [ -f "${recipe_dir}/${post_build_file}" ]; then
  {
    cat "${recipe_dir}/${post_build_file}"
    echo ""
  } >> "${directory}/${build_script}"
fi

# build the package in the sandbox

pushd "${source_dir}"
chmod u+x "${directory}/${build_script}"
mkdir -p "${prefix_dir}"
env -i "${directory}/${build_script}"
popd

if [ -f "${recipe_dir}/${build_file}" ]; then
  find "${prefix_dir}" -name '*.la' -delete
  package-wheel.sh --build-number "${build_number}" --compat-tag "${compat_tag}" --package "${package}" --prefix-dir "${prefix_dir}" --source-dir "${source_dir}" --version "${version}"
fi

echo "${0##*/} completed successfully."
