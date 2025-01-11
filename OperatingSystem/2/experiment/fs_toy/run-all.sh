#!/usr/bin/env bash

# Run all the scripts in the current directory
#
# Acquire have installed gnu make


make -v >/dev/null 2>&1

if [ ! $?  ]; then
    echo "GNU make is not installed"
    exit 1
fi

make all

make run
