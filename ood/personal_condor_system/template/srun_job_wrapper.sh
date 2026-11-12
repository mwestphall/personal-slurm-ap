#!/bin/bash
# Read the numeric attributes for CPU and Memory from this slot's machine ad
cpus=$(sed -n -E "s/^Cpus\s*=\s*\"?([0-9]+).*/\1/p"   "$_CONDOR_MACHINE_AD" | head -n1)
mem=$(sed  -n -E "s/^Memory\s*=\s*\"?([0-9]+).*/\1/p" "$_CONDOR_MACHINE_AD" | head -n1)

exec srun -vvv --ntasks=1 --nodes=1 --exact --export=ALL --unbuffered --cpus-per-task="${cpus}" --mem="${mem}M" "$@"
