#!/bin/bash

if [ ! -d "build" ];then
  mkdir -p build
fi

build_type="Debug"

if [ "$1" == "r" ];then
  build_type="Release"
fi


pushd build >/dev/null 2>&1 || exit

cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE="${build_type}"
ninja -v

popd >/dev/null 2>&1 || exit