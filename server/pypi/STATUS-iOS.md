# iOS Known problems

## All Python Versions

- blis: no idea...
- chaquopy-flac: linking problem with missing symbols
- chaquopy-geos: C++ linking issue
- chaquopy-hdf5: Source code no longer available?
- chaquopy-libcxx: makes some assumptions about how the toolchain directory is laid out
- chaquopy-libffi: not needed; replaced with libffi from Python-Apple-support
- chaquopy-libgfortran: Needs a fortran compiler.
- chaquopy-libomp: Isn't a build; copies a file from the Android toolchain
- chaquopy-libraw: Checks for modified autoconf files, asks for aclocal-1.15
- chaquopy-libsndfile: needs chaquopy-flac
- chaquopy-libvorbis: build fails; uint16_t not recognized on x86_64
- chaquopy-libxslt: issue with iconv linkage from libxml?
- chaquopy-libzmq: linking problem with missing symbols. Likely needs an update to configure to add flags for iOS
- chaquopy-llvm: Needs cmake
- chaquopy-openblas: needs chaquopy-libfortran
- chaquopy-secp256k1: No tarball, so config.sub is generated, but needs patching.
- cmake-example: Needs Cmake
- coincurve: needs chaquopy-secp256k1
- cryptography
- cvxopt: needs chaquopy-openblas
- dlib: needs chaquopy-openblas
- gevent: needs greenlet; issue with inline libev configure
- grpcio: Unknown; failed during build
- h5py: needs chaquopy-hdf5
- llvmlite: needs chaquopy-llvm
- lxml: needs chaquopy-libxml2, chaquopy-libxslt
- numba: needs numpy; fails due to a config-reading process needing npymath
- opencv-contrib-python: needs chaquopy-libfortran
- opencv-contrib-python-headless: needs chaquopy-libfortran
- opencv-python: Uses scikit-build, which doesn't understand iOS
- opencv-python-headless: needs chaquopy-libfortran
- psutil: doesn't make any sense on iOS?
- pycares: missing ares_config.h?
- pycrypto
- pycryptodome: possible configuration problem; binary artefacts aren't consistent between platforms
- pycryptodomex: possible configuration problem; binary artefacts aren't consistent between platforms
- pysha3
- python-example: cmake failure
- pyzmq: needs chaquopy-libzmq
- rawpy: subrepo cloning failure?
- rpi-gpio: does this make any sense? Fails build due to missing sys/epoll.h
- scikit-image: needs numpy; numpy configuration problem[after_install.sh](..%2F..%2F..%2Finnodem%2Fin-api%2Fcodedeploy%2Fafter_install.sh)
- scikit-learn: needs numpy, scipy, chaquopy-openblas
- scipy: needs numpy; can't find at build time
- sentencepiece: cmake build failure
- shapely: needs chaquopy-geos
- soundfile: needs chaquopy-libsndfile
- spacy: needs srsly, blis
- statsmodels: cythonize problem
- ta-lib: needs chaquopy-ta-lib, numpy
- tensorflow: needs numpy on build host
- tflite-runtime: numpy build problem; get_include()?
- thinc: package definition problem
- tokenizers: needs rust?
- torch: needs numpy, chaquopy-libfortran, chaquopy-openblas
- torchvision: needs torch
- xgboost: CMake configuration problem

## Python 3.10

- backports-zoneinfo: Not needed, as zoneinfo was introduced in Python 3.10
- preshed: cython compilation issue; no obvious fix through upgrading

## Python 3.11

- backports-zoneinfo: Not needed, as zoneinfo was introduced in Python 3.10
- editdistance:
- gensim:
- murmurhash:
- preshed: cython compilation issue; no obvious fix through upgrading
- twisted:
- wordcloud: