# Personal HTCondor System on Slurm

This repository contains instructions for launching a single-user HTCondor system on Slurm, through CHTC's [Open OnDemand instance](https://ondemand.chtc.wisc.edu/), or generically via the `sbatch` command line tool:

- Creating an HTCondor Submit Node (Access Point) for queueing HTCondor jobs, as a single-node Slurm Job.
- Submitting HTCondor jobs to your Access Point via your Slurm cluster's login node terminal.
- Creating a full HTCondor system consisting of an Access Point and Worker Nodes (Execution Points) to run your submitted jobs.

## Running an HTCondor System via CHTC Open OnDemand 

The following instructions pertain to running an HTCondor system on CHTC's Open OnDemand web instance. for instructions in installing
the HTCondor Open OnDemand app into another cluster, see [INSTALL.md](INSTALL.md)

### Log into CHTC's Open OnDemand

CHTC's Open OnDemand instance can be accessed at [ondemand.chtc.wisc.edu](https://ondemand.chtc.wisc.edu/). Log in using your UW NetID and Password.

If you are new to CHTC and need help setting up an account, [apply for access](https://chtc.wisc.edu/uw-research-computing/form.html) via the CHTC user app.

If you are an existing CHTC user and are unable to access Open OnDemand, contact the CHTC [facilitation team](https://chtc.cs.wisc.edu/uw-research-computing/get-help.html) for help.

### Schedule an HTCondor Access Point on your Slurm Cluster

Your Personal HTCondor access point runs as a single-node Slurm job. Your Access Point manages your HTCondor job queue.

To launch an instance of the **Create Personal HTCondor Access Point** interactive app:

1. Navigate to the "Interactive Apps" section of the Open OnDemand dashboard.

1. Select "Create Personal HTCondor Access Point".

1. In the app's submission form, select a Slurm partition for your AP. Your AP uses a fixed 1 CPU and 2 GB of RAM.

1. Check the "Create Sample Submit File" checkbox to create a test HTCondor job description. 

1. "Launch" the app.

1. Watch the status of your AP interactive app. Wait for the AP app to reach the "Running" state. 

### Submit your first HTCondor Job

Place a "Hello World" HTCondor job into your AP's job queue. The sample job description created by the 
**Create Personal HTCondor Access Point** is used in this step.

1. Access the Spark Login Node

    Open a Shell on the Spark login node via the "CHTC Spark Cluster Shell Access" menu item in Open OnDemand.
    You will be prompted to log in again with your NetID and password.

1. Set up your HTCondor environment

    Source the following file in your home directory. This file configures the HTCondor command line tools on the
    Spark login node to run against your Personal AP:

    ```
    . ~/personal-htcondor/current-ap/condor.sh
    ```

    You may also add the above line to your `~/.bashrc` to perform this configuration on every login.

1. Change to your Sample Job's directory

    ```
    cd ~/personal-htcondor/sample-submit
    ```

1. Submit your HTCondor Job to your AP

    ```
    condor_submit hello.sub
    ```

1. Confirm that your Job Runs on the EP

    ```
    condor_watch_q
    ```

1. Check the output of your job after it finishes

    ```
    cat hello.out
    ```

1. If the job ran successfully, expect output similar to:

    ```
    Hello, World!
    I am running on hpc-worker123
    ```

### Schedule an HTCondor System to run your jobs

Once you've prepared your HTCondor job queue via the **Create Personal HTCondor Access Point** app, launch
a full HTCondor system to run your queued jobs via the **Create Personal HTCondor System** app.

1. Navigate to the "Interactive Apps" section of the Open OnDemand dashboard.

1. Select "Create Personal HTCondor System".

1. In the app's submission form, select a Slurm partition for your HTCondor System.

1. Select a CPU and Memory allocation for your HTCondor Execution Point. An additional 1 CPU and 2 GB of RAM will be
   allocated on top of this for an Access Point in this system.

1. "Launch" the app.

1. Watch the status of your AP interactive app. Wait for the AP app to reach the "Running" state.

1. Watch the progress of your HTCondor Job Queue via the interactive app's job queue overview.

## Running an HTCondor System via `sbatch`

If you do not have access to the HTCondor Open OnDemand interactive apps, you may also schedule an
HTCondor System directly via `sbatch`.

### Prerequisites

1. Ensure `git` is installed on your Slurm login node. Download this repository to your home directory via

   ```
   git clone https://github.com/mwestphall/personal-slurm-ap.git
   ```

1. The HTCondor system uses a shared filesystem for communication between your Slurm login node and your
   Access Point on a Slurm worker node. Select a location on your shared filesystem as the base install dir for
   your AP.

### Schedule an HTCondor Access Point on your Slurm Cluster

Your Personal HTCondor Access Point runs as a single-node Slurm job. Your Access Point manages your HTCondor job queue.

To launch an HTCondor Access Point via `sbatch`:

1. `cd` to the `ap` directory of this repository:

   ```
   cd ~/personal-slurm-ap/ap
   ```

1. Submit `entrypoint.sh` via `sbatch`. The Access Point requests 1 CPU and 2 GB RAM by default, which should be sufficient
   for most single-user job queues.

   ```
   sbatch entrypoint.sh --base-dir <shared-fs-dir>
   ```

1. Tail the created job's logs to confirm that the Access Point starts successfully.

  ```
  $ tail -f slurm-<jobid>.out
  ...
  0: ==> To interact with this AP from the login node, source the condor env file at <shared-fs-dir>/condor-<jobid>/condor.sh:
  0:     '. <shared-fs-dir>/condor-<jobid>/condor.sh'
  ```

1. Source the environment file indicated in the job logs, then confirm that you can contact both running daemons on the Access Point.
   `condor_q` lists the jobs in the Access Point's job queue, while `condor_status` lists all running HTCondor daemons connected to
   the Access Point.

   ```
   $ . <shared-fs-dir>/condor-<jobid>/condor.sh

   $ condor_q
   
   -- Schedd: hpc-worker100.slurm.cluster : <192.168.0.1:9618?... @ 08/28/26 14:11:15
   OWNER BATCH_NAME      SUBMITTED   DONE   RUN    IDLE   HOLD  TOTAL JOB_IDS
   
   Total for query: 0 jobs; 0 completed, 0 removed, 0 idle, 0 running, 0 held, 0 suspended 
   Total for all users: 0 jobs; 0 completed, 0 removed, 0 idle, 0 running, 0 held, 0 suspended

   $ condor_status -any
   MyType             TargetType         Name                                     
   
   Collector          None               My Pool - hpc-worker100.slurm.cluster@hpc-worker100.slurm.cluster
   Scheduler          None               hpc-worker100.slurm.cluster
   Submitter          None               you@hpc-worker100.slurm.cluster
   ```

### Submit your first HTCondor Job

Submit a "Hello World" HTCondor job to your Access Point's job queue. 

1. Change directories to `examples/hello_world` and examine its contents. It contains a 
   submit description file (`hello.sub`) and an executable bash script (`hello.sh`).


   ```
   $ cd examples/hello_world
   $ less hello.sub
   $ less hello.sh
   ```

1. Submit your HTCondor job to your AP

   ```
   condor_submit hello.sub
   ```

1. Confirm that your job has been enqueued successfully

   ```
   $ condor_q
   
   -- Schedd: hpc-worker100.slurm.cluster : <192.168.0.1:9618?... @ 08/28/26 14:11:15
   OWNER BATCH_NAME      SUBMITTED   DONE   RUN    IDLE  TOTAL JOB_IDS
   you   ID: 1         11/10 11:46      _     _       1      1 1.0
   
   Total for query: 1 jobs; 0 completed, 0 removed, 1 idle, 0 running, 0 held, 0 suspended 
   Total for all users: 1 jobs; 0 completed, 0 removed, 1 idle, 0 running, 0 held, 0 suspended
   ```

### (Optional) Submit a multi-stage HTCondor DAG

For an example of HTCondor workflow management, submit a multi-stage DAG (Directed Acyclic Graph) to 
your Access Point's job queue.

1. Change directories to `examples/dag_plot` and examine its contents. It contains:
   - A DAG description file describing a three-stage workflow (`square_and_plot.dag`)
   - Submit description files for each stage of the workflow (`square.sub`, `mksif.sub`, and `plot.sub`)
   - An executable script for each stage of the workflow (`square.sh` and `plot.R`)
   - A list of inputs for the first stage of the workflow (`numbers.txt`)

1. Note the features of the submit description files:
   - `square.sub` contains the queue statement `queue number from numbers.txt`. This instructs
     your AP to queue a list of jobs, with one instance per line in the input file.
   - `mksif.sub` contains a `shell = apptainer build` statement that pre-builds an `R` container
     environment for `plot.sub`. This translates the default Docker `R` container into an Apptainer SIF
     file.
   - `plot.sub` contains a container environment description `container_image = r.sif`.
     This instructs an EP running your job to run it inside of the `R` container environment from
     `mksif.sub`.

1. Submit your HTCondor DAG to your AP

   ```
   condor_submit_dag square_and_plot.dag
   ```

1. Confirm that your DAG jobs have been enqueued successfully

### Schedule an HTCondor System to run your jobs

Once you've prepared your HTCondor job queue, launch a full HTCondor system to run your queued jobs.

1. `cd` to the `ap` directory of this repository:

   ```
   cd ~/personal-slurm-ap/ap
   ```

1. Re-submit `entrypoint.sh` via `sbatch`, adding the `--system` argument to include an Execution Point alongside the Access Point.
   Set the resource requirements for this Execution Point as desired via sbatch args:

   ```
   sbatch --cpus-per-task=4 --mem=8G entrypoint.sh --base-dir <shared-fs-dir> --system
   ```

1. Confirm that the Execution Point successfully registers with the Access Point:

   ```
   $ condor_status
   Name                              OpSys      Arch     State     Activity  LoadAv  Mem    ActivityTime

   slot1@hpc-worker101@hpc-worker101 LINUX      X86_64   Unclaimed Idle      0.000   8192   0+00:00:30

               Total Owner Claimed Unclaimed Matched Preempting  Drain Backfill BkIdle

   X86_64/LINUX     1     0       0        1       0          0      0        0      0

          Total     1     0       0        1       0          0      0        0      0
   
   ```

1. Confirm that your previously scheduled HTCondor job runs on the EP:

   ```
   $ condor_q
   
   -- Schedd: hpc-worker100.slurm.cluster : <192.168.0.1:9618?... @ 08/28/26 14:11:15
   OWNER BATCH_NAME      SUBMITTED   DONE   RUN    IDLE  TOTAL JOB_IDS
   you   ID: 1         11/10 11:46      _     1       0      1 1.0
   
   Total for query: 1 jobs; 0 completed, 0 removed, 0 idle, 1 running, 0 held, 0 suspended 
   Total for all users: 1 jobs; 0 completed, 0 removed, 0 idle, 0 running, 0 held, 0 suspended
   ```

1. Check the output of your job after it finishes:

   ```
   $ cat hello.out
   Hello, World!
   I am running on hpc-worker123
   ```

### (Optional) Schedule an HTCondor System with GPUs to run your jobs

HTCondor will automatically detect and use any GPUs allocated to its Slurm job. To schedule
an HTCondor system with GPUs:

1. Ensure that you are submitting to a partition that contains GPUs.
1. Add a GPU request to your `sbatch` command.

```
sbatch --cpus-per-task=4 --mem=8G --part gpu --gres gpu:1 entrypoint.sh --base-dir <shared-fs-dir> --system
```
