#!/bin/bash

if [ ! -d "build" ];then
  mkdir -p build
fi

pushd build >/dev/null 2>&1 || exit

cmake .. -G Ninja
ninja -v

popd >/dev/null 2>&1 || exit

echo -e "\n\033[1;33m=======start running======\033[0m\n"

./bin/banker
