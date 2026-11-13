#!/bin/bash
# Read the numeric attributes for CPU and Memory from this slot's machine ad
cpus=$(sed -n -E "s/^Cpus\s*=\s*\"?([0-9]+).*/\1/p"   "$_CONDOR_MACHINE_AD" | head -n1)
mem=$(sed  -n -E "s/^Memory\s*=\s*\"?([0-9]+).*/\1/p" "$_CONDOR_MACHINE_AD" | head -n1)

srun -vvv --ntasks=1 --nodes=1 --exact --export=ALL --unbuffered --cpus-per-task="${cpus}" --mem="${mem}M" \
     /usr/bin/sh -c "
     cat /proc/self/cgroup > .slurm_cgroup
     $@
     "
rc=$?

SLURM_CGROUP=$(cat .slurm_cgroup | sed "s/0::/\/sys\/fs\/cgroup/")
echo "Ran in Slurm CGroup: $SLURM_CGROUP"

OOM_COUNT=$(sed -n -E 's/oom_kill ([0-9]+)/\1/p' $SLURM_CGROUP/memory.events)
echo "Got $OOM_COUNT OOM events"

# Use a reserved exit code for Slurm OOM
if [[ $OOM_COUNT -gt 0 ]]; then
    exit 125
fi

exit $rc
