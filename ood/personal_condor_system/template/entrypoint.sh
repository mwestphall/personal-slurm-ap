#!/bin/bash
#
# entrypoint.sh - Thin wrapper around install.sh and start.sh, sourced by each
# OOD app's rendered script.sh.erb, which sets BASE_DIR, REUSE_AP,
# and LAUNCH_EP from the OOD form, plus EP_CPUS and EP_MEM_GB when
# LAUNCH_EP is 1, and AP_DIR to this directory. The source of truth is
# ood/personal_condor_system/template/; ./install.sh copies it (and the scripts
# it calls) into ood/personal_ap/template/ so each app is self-contained.

BASE_DIR="${BASE_DIR:-/scratch/$USER}" # only used for a fresh install
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

# True if another process holds the AP's InstanceLock (set via LOCK in
# install.sh's 15-ap-lock.conf). Absent lock file means nobody holds it.
ap_lock_held() {
    local lock="$CONDOR_DIR/lock/InstanceLock"
    [ -e "$lock" ] || return 1
    ! flock --nonblock "$lock" true
}

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
    SLURM_SUBMIT_DIR="$AP_DIR" "${SRUN[@]}" --cpus-per-task="$EP_CPUS" --mem="${EP_MEM_GB}G" \
        "$BASH" -c 'EP_ID="$SLURM_JOB_ID" exec bash "$0/annex-ep.sub" "$1"' \
        "$AP_DIR" "$BASE_DIR"
}

if [ "${LAUNCH_EP:-0}" = "1" ]; then
    launch_ep &
fi

# When resuming, another AP may still be running on this install. Wait for it
# to release its lock before touching any AP config. The EP launched above
# is expected to pick up that AP's config in the meantime. If several jobs
# wait at once, whichever polls first after the release wins; the rest keep
# waiting once their AP start takes the lock.
if [ "${RESUMING:-0}" = "1" ]; then
    while ap_lock_held; do
        echo "==> AP lock at $CONDOR_DIR/lock/InstanceLock is held by another AP; waiting"
        sleep 10
    done
fi

# Periodically write the file that view.html.erb reads, into the AP's shared
# dir. Runs in the background alongside the AP, and is cleaned up with the job.
"$AP_DIR/update-view.sh" --condor-dir "$CONDOR_DIR" &

exec "${SRUN[@]}" --cpus-per-task=1 --mem=2G "$BASH" "$AP_DIR/start.sh" --condor-dir "$CONDOR_DIR"
