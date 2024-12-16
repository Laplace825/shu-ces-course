#!/bin/bash

if [ ! -d "build" ];then
  mkdir -p build
fi

build_type="debug"

if [ "$1" == "r" ];then
  build_type="release"
fi

make build-${build_type}
