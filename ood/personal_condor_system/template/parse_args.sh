#!/bin/bash
#
# parse_args.sh - Sourced by entrypoint.sh with its arguments. Sets BASE_DIR,
# REUSE_AP and LAUNCH_EP from their defaults and entrypoint.sh's flags (see
# usage below), and, with --system, derives EP_CPUS and EP_MEM_GB from the
# job's Slurm resource request. Any variable already set (by an OOD app's
# script.sh.erb) is kept as the default, then flags apply on top.

usage() {
    cat <<EOF
Usage: sbatch [sbatch options] entrypoint.sh [options]

Options:
  --base-dir <path>  Where a fresh AP is installed (default: /scratch/\$USER).
  --discard-queue    Don't resume the existing AP and its job queue; install
                     a fresh AP with a new queue. Default is to resume.
  --system           Launch a whole condor system: an EP alongside the AP.
                     The EP gets the job's resources beyond the AP's 1 CPU and
                     2 GB, so request those on top of what the EP should have.
  --help             Print this help message and exit.
EOF
}

BASE_DIR="${BASE_DIR:-/scratch/$USER}" # only used for a fresh install
REUSE_AP="${REUSE_AP:-1}"
LAUNCH_EP="${LAUNCH_EP:-0}"

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        --base-dir)
            if [ $# -lt 2 ]; then
                echo "error: --base-dir requires a path argument" >&2
                exit 1
            fi
            BASE_DIR="$2"
            shift 2
            ;;
        --discard-queue)
            REUSE_AP=0
            shift
            ;;
        --system)
            LAUNCH_EP=1
            shift
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# The EP's share of the job is whatever the job requested beyond the AP's 1 CPU
# and 2 GB. Derive it from Slurm's variables unless already set (by OOD).
if [ "$LAUNCH_EP" = "1" ] && { [ -z "${EP_CPUS:-}" ] || [ -z "${EP_MEM_GB:-}" ]; }; then
    JOB_CPUS="${SLURM_CPUS_PER_TASK:-${SLURM_CPUS_ON_NODE:-}}"
    if [ -n "${SLURM_MEM_PER_NODE:-}" ]; then
        JOB_MEM_MB="$SLURM_MEM_PER_NODE"
    elif [ -n "${SLURM_MEM_PER_CPU:-}" ] && [ -n "$JOB_CPUS" ]; then
        JOB_MEM_MB=$((SLURM_MEM_PER_CPU * JOB_CPUS))
    else
        JOB_MEM_MB=""
    fi
    if [ -z "$JOB_CPUS" ] || [ -z "$JOB_MEM_MB" ]; then
        echo "error: --system needs the job's CPU and memory request (sbatch --cpus-per-task and --mem)" >&2
        exit 1
    fi
    EP_CPUS="${EP_CPUS:-$((JOB_CPUS - 1))}"
    EP_MEM_GB="${EP_MEM_GB:-$((JOB_MEM_MB / 1024 - 2))}"
    if [ "$EP_CPUS" -lt 1 ] || [ "$EP_MEM_GB" -lt 1 ]; then
        echo "error: --system needs more than the AP's 1 CPU and 2 GB; the job leaves the EP $EP_CPUS CPUs, ${EP_MEM_GB}G" >&2
        exit 1
    fi
fi
