#!/usr/bin/env bash

# This script is used to run the application

dd if=/dev/zero of=disk.img bs=1M count=1024

docker run -it --rm --privileged -v "$(pwd)/disk.img:/disk.img" \
    file_op2 bash
