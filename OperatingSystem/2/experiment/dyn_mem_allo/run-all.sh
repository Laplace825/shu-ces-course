#!/bin/bash 

# FirstFit;
# RecursiveFirstFit;
# BestFit;
# WorstFit;

ALLOCATORS=(FirstFit RecursiveFirstFit BestFit WorstFit)

for allocator in "${ALLOCATORS[@]}"; do
  echo "Running $allocator"
  MEM_ALLOC_TYPE="${allocator}" ./bin/release/dyn_allo_mem > "result_${allocator}.txt"
done
