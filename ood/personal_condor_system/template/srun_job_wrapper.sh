#!/bin/bash
# Read the numeric attributes for CPU and Memory from this slot's machine ad
cpus=$(sed -n -E "s/^Cpus\s*=\s*\"?([0-9]+).*/\1/p"   "$_CONDOR_MACHINE_AD" | head -n1)
mem=$(sed  -n -E "s/^Memory\s*=\s*\"?([0-9]+).*/\1/p" "$_CONDOR_MACHINE_AD" | head -n1)

srun -vvv --ntasks=1 --nodes=1 --exact --export=ALL --unbuffered --cpus-per-task="${cpus}" --mem="${mem}M" \
     /usr/bin/sh -c "
     echo \$SLURM_JOB_ID.\$SLURM_STEP_ID > .slurm_step
     cat /proc/self/cgroup | sed "s/0::/\/sys\/fs\/cgroup/" > .slurm_cgroup
     $@
     "
rc=$?

SLURM_STEP=$(cat .slurm_step)
echo "Ran as slurm step: $SLURM_STEP"

SLURM_CGROUP=$(cat .slurm_cgroup)
echo "Ran in Slurm CGroup: $SLURM_CGROUP"
cat $SLURM_CGROUP/memory.events

SACCT_STATE=$(sacct -j $SLURM_STEP --format=State -P -n)
echo "sacct reporting on this job step: $SACCT_STATE"

# Use a reserved exit code for Slurm OOM
if [[ "$SACCT_STATE" == "OUT_OF_MEMORY" ]]; then
    exit 125
fi

exit $rc
