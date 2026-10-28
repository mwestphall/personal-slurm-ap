#!/bin/bash
# Runs inside the annex-ep.sub Apptainer container. Inputs are bind-mounted
# read-only under /annex-in; the EP working dir is bind-mounted at /ep.
# Expects AP_DIR and EP_ID in the environment.

cd /ep || {
  echo "ERROR: /ep is not mounted"
  exit 1
}

echo "Unpacking /annex-in/annex.tar"
tar -xvf /annex-in/annex.tar --strip-components=1

echo ""
echo "Displaying working directory"
ls -alh

echo ""
echo "Executing annex setup script"
bash annex-setup.sh

# Install the properly-scoped token minted outside the container; the bundled
# one is scope-clipped to READ/WRITE.
cp /annex-in/annex.token annex.token
chmod 600 annex.token

echo ""
echo "Configuring dynamic collector and schedd-name lookup"
# AP_SCHEDD_ADDRESS_FILE just passes this path to the cron job below; see
# notes.md's "AP Address Polling" and update-annex-collector.sh.
cat >> 20-annex-pilot-instance <<EOT

AP_SCHEDD_ADDRESS_FILE = ${AP_DIR}/local/spool/.schedd_address

# Make this EP's names unique by appending its EP ID, so EPs sharing a
# worker node don't collide in the AP's collector. UID_DOMAIN and the default
# daemon names otherwise derive from the node's FULL_HOSTNAME alone.
UID_DOMAIN = \$(FULL_HOSTNAME)-${EP_ID}
STARTD_NAME = \$(FULL_HOSTNAME)-${EP_ID}
MASTER_NAME = \$(FULL_HOSTNAME)-${EP_ID}

STARTD_CRON_JOBLIST = \$(STARTD_CRON_JOBLIST) UPDATE_ANNEX_COLLECTOR
STARTD_CRON_UPDATE_ANNEX_COLLECTOR_EXECUTABLE = /annex-in/update-annex-collector.sh
STARTD_CRON_UPDATE_ANNEX_COLLECTOR_ARGS = \$(AP_SCHEDD_ADDRESS_FILE)
STARTD_CRON_UPDATE_ANNEX_COLLECTOR_MODE = Periodic
STARTD_CRON_UPDATE_ANNEX_COLLECTOR_PERIOD = 60
STARTD_CRON_LOG_NON_ZERO_EXIT = True
EOT

echo ""
echo "Executing HTC annex slurm script"
# annex-setup.sh wraps its node script in `srun` whenever SLURM_JOBID is set,
# and srun isn't available in the container. Unset it (SLURM_JOB_ID stays set)
# so it runs directly.
unset SLURM_JOBID
export SLURM_EXPORT_ENV=ALL
bash hpc.slurm > annex-job.out 2> annex-job.err
status=$?
echo "hpc.slurm exited with status ${status}"
exit "${status}"
