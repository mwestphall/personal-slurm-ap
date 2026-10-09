# Personal HTCondor Cluster on CHTC Open OnDemand

This repository contains instructions for launching a single-user HTCondor cluster on CHTC's [Open OnDemand instance](https://ondemand.chtc.wisc.edu/):

- Creating an HTCondor cluster consisting of a Submit Node (Acess Point) and Worker Nodes (Execution Points), as a multi-node Slurm Job.
- Submitting HTCondor jobs to your cluster using Open OnDemand's interactive web terminal.

# Log into CHTC's Open OnDemand

CHTC's Open OnDemand instance can be accessed at [ondemand.chtc.wisc.edu](https://ondemand.chtc.wisc.edu/). Log in using your UW NetID and Password.

If you are new to CHTC and need help setting up an account, [apply for access](https://chtc.wisc.edu/uw-research-computing/form.html) via the CHTC user app.

If you are an existing CHTC user and are unable to access Open OnDemand, contact the CHTC [facilitation team](https://chtc.cs.wisc.edu/uw-research-computing/get-help.html) for help.

# Schedule an HTCondor Cluster on your Slurm Cluster

Your Personal HTCondor cluster runs as a multi-node Slurm job. One node in this job runs an Access Point,
which manages your HTCondor job queue. The remaining nodes run Execution Points, which run your HTCondor jobs.

To launch an instance of the **Create Personal HTCondor** interactive app:

1. Navigate to the "Interactive Apps" section of the Open OnDemand dashboard.

   ![Interactive App Dropdown](/docs/interactive-apps.png)

1. Select "Create Personal HTCondor".

1. In the app's submission form, select a slurm partition, resource requests, and EP count for your AP.
    - All fields may be left as the default.

1. Check the "Create Sample Submit File" checkbox. This creates a sample executable file, 
   and a submit description file for running this executable as an HTCondor job, in
   `~/personal-htcondor/sample-submit`.

1. "Launch" the app.

1. Watch the status of your AP interactive app. Wait for the AP app to reach the "Running" state. 

   ![AP Status](/docs/ap-status.png)

# Submit your first HTCondor Job

Your AP and EP interactive apps comprise a complete HTCondor cluster. HTCondor jobs submitted to your AP
will run on your EP. 

Place a "Hello World" HTCondor job into your AP's job queue.


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

# Additional Utilities

## Resume an Access Point

The AP configured by the **Personal HTCondor AP** app will exit after 4 hours by default. To resume your AP after it exits,
re-run the Personal AP interactive app, ensuring that the "Resume AP" checkbox is checked.

To launch a fresh AP, discarding your previous instance, re-run the app with the "Resume AP" checkbox unchecked.

![Reuse AP](/docs/reuse-ap.png)

**Note:** For best results, avoid scheduling multiple simultaneous instances of the Personal AP interactive app. Ensure that your previous
instance of the app is completed or cancelled before scheduling a new instance.

## Add Execution Points

To run larger workloads on your HTCondor cluster, you can schedule additional EPs by re-running the **Personal HTCondor EP** interactive app.

Each simultaneous instance of the EP app will provide additional compute capacity to your cluster.
