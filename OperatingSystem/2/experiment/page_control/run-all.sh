#!/bin/bash

Algo_type=(FIFO LRU OPT)

for algo in "${Algo_type[@]}"
do
    echo "Running $algo"
    cargo run --release -- "$algo" > result_"$algo".txt
done
