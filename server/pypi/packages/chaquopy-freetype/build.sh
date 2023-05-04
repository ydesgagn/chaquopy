#!/bin/bash
set -eu

cp -f docs/FTL.TXT LICENSE
./configure --host=$CHAQUOPY_TRIPLET --without-harfbuzz --without-png
make -j $CPU_COUNT
make install prefix=$PREFIX

mv $PREFIX/include/freetype2/* $PREFIX/include
rmdir $PREFIX/include/freetype2

# Some versions of Android (e.g. API level 26) have a libft2.so in /system/lib, but our copy
# has an SONAME of libfreetype.so, so there's no conflict.
# rm -r $PREFIX/lib/{*.a,*.la,pkgconfig}
rm -r $PREFIX/lib/{*.la,pkgconfig}

rm -r $PREFIX/share
