#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=1:00:00
#
# The #SBATCH defaults above (override them on the sbatch command line) are the
# AP's 1 CPU and 2 GB. To additionally allocate an EP with --system, you must
# request resources above the defaults
#
# entrypoint.sh - Thin wrapper around install.sh and start.sh that runs a
# personal HTCondor AP (and optionally one EP) inside a Slurm job. It can be
# submitted directly:
#
#   cd <dir containing entrypoint.sh> && sbatch [sbatch options] entrypoint.sh [--base-dir <path>] [--discard-queue] [--system]
#
# (see parse_args.sh, or --help, for the options) or sourced by an Open OnDemand
# app's rendered script.sh.erb, which presets BASE_DIR, REUSE_AP, LAUNCH_EP,
# EP_CPUS, EP_MEM_GB and AP_DIR from the OOD form. The source of truth is
# ood/personal_condor_system/template/; ./install.sh copies it (and the scripts
# it calls) into ood/personal_ap/template/ so each app is self-contained.

# The directory holding this script and the scripts it calls. Under sbatch,
# Slurm runs a spooled copy of the script, so BASH_SOURCE is no use there;
# sbatch must instead be run from this directory, which Slurm records as
# SLURM_SUBMIT_DIR. Outside Slurm, use the script's own directory.
if [ -z "${AP_DIR:-}" ]; then
    AP_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
fi
if [ ! -f "$AP_DIR/parse_args.sh" ]; then
    echo "error: parse_args.sh not found in $AP_DIR; run sbatch from the directory containing entrypoint.sh" >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$AP_DIR/parse_args.sh" "$@"

CURRENT_AP="$HOME/personal-htcondor/current-ap"

if [ "$REUSE_AP" = "1" ] && [ -d "$CURRENT_AP" ]; then
    echo "==> Resuming existing AP at $CURRENT_AP"
    RESUMING=1
else
    echo "==> Installing a fresh AP"
    if ! INSTALL_OUTPUT="$("$AP_DIR/install.sh" --base-dir "$BASE_DIR")"; then
        echo "$INSTALL_OUTPUT"
        echo "error: install.sh failed" >&2
        exit 1
    fi
    echo "$INSTALL_OUTPUT"
fi

CONDOR_DIR="$(readlink -f "$CURRENT_AP")"

# The job runs on a single node. The AP runs as a job step on 1 CPU and 2 GB of
# memory. With LAUNCH_EP=1, the job requested that on top of the user's request,
# and one EP runs as a second step on the rest of the job's resources.
# OOD submits with a restricted environment that srun steps inherit, leaving
# a step without PATH ("execve(): bash: No such file or directory"), so pass
# this script's environment through and give srun bash's absolute path.
# --cpus-per-task and --mem are explicit because srun doesn't reliably inherit
# them from the job ("More processors requested than permitted" otherwise).
# --exact keeps the steps on disjoint resources so they can run concurrently.
SRUN=(srun --label --export=ALL --exact --nodes=1 --ntasks=1)
BASH="$(command -v bash)"

# Wait for the AP to finish building the annex tarball, then start the EP. Only
# used when LAUNCH_EP=1 (the AP + EP app).
launch_ep() {
    local ready="$CONDOR_DIR/annex-ready" waited=0
    while [ ! -f "$ready" ]; do
        if [ "$waited" -ge 300 ]; then
            echo "error: AP annex not ready after 300s; not launching the EP" >&2
            return 1
        fi
        sleep 2
        waited=$((waited + 2))
    done

    echo "==> Launching the EP on $EP_CPUS CPUs, ${EP_MEM_GB}G"

    # annex-ep.sub locates update-annex-collector.sh via SLURM_SUBMIT_DIR. A
    # preset EP_ID tells it it is running inside a job step.
    SLURM_SUBMIT_DIR="$AP_DIR" "${SRUN[@]}" --cpus-per-task="$EP_CPUS" --mem="${EP_MEM_GB}G"  --overlap \
        "$BASH" -c 'EP_ID="$SLURM_JOB_ID" exec bash "$0/annex-ep.sub" "$1"' \
        "$AP_DIR" "$BASE_DIR"
}

if [ "${LAUNCH_EP:-0}" = "1" ]; then
    launch_ep &
fi

# When resuming, another AP may still be running on this install. Block until
# it releases its InstanceLock (see install.sh's 15-ap-lock.conf) before
# touching any AP config. The EP launched above is expected to pick up that
# AP's config in the meantime. If several jobs wait at once, whichever the
# kernel wakes first wins; we don't guard against the rest.
if [ "${RESUMING:-0}" = "1" ]; then
    "$AP_DIR/wait-for-lock.py" "$CONDOR_DIR/lock/InstanceLock" || \
        echo "warning: could not wait on the AP lock; starting anyway" >&2
fi

# Periodically write the file that view.html.erb reads, into the AP's shared
# dir. Runs in the background alongside the AP, and is cleaned up with the job.
"$AP_DIR/update-view.sh" --condor-dir "$CONDOR_DIR" &

exec "${SRUN[@]}" --cpus-per-task=1 --mem=2G "$BASH" "$AP_DIR/start.sh" --condor-dir "$CONDOR_DIR"
