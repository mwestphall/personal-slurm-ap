#!/bin/bash
# Read a numeric attribute from this slot's machine ad
ad_get() {
    sed -n -E "s/^$1[[:space:]]*=[[:space:]]*\"?([0-9]+).*/\1/Ip" "$_CONDOR_MACHINE_AD" | head -n1
}

cpus=$(ad_get Cpus)
mem=$(ad_get Memory)     # MiB
gpus=$(ad_get Gpus)

args=(--ntasks=1 --nodes=1 --exact --export=ALL --unbuffered
    --cpus-per-task="${cpus:-1}" --mem="${mem:-1024}M")
[ -n "$gpus" ] && [ "$gpus" -gt 0 ] && args+=(--gpus="$gpus")

echo "slot ad: cpus=$cpus mem=$mem gpus=$gpus"
printf '%q ' srun "${args[@]}" "$@"
echo
exec srun -vvv "${args[@]}" "$@"
