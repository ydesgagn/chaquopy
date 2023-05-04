#!/usr/bin/env bash
set -e

{
  echo "[openblas]"
  echo "libraries = openblas"
  echo "library_dirs = $(brew --prefix openblas)/lib"
  echo "include_dirs = $(brew --prefix openblas)/include"
  echo "runtime_library_dirs = $(brew --prefix openblas)/lib"
} > site.cfg
