# Sample "Hello World" Job

This directory holds a small HTCondor job (`hello.sub` and `hello.sh`) for trying out your
personal HTCondor cluster. To run it:

1. Open a shell on the login node and set up your HTCondor environment:

    ```
    . ~/personal-htcondor/current-ap/condor.sh
    ```

1. From this directory, submit the job to your AP:

    ```
    condor_submit hello.sub
    ```

1. Watch the job run on one of your EPs (press Ctrl+C to exit):

    ```
    condor_watch_q
    ```

1. After the job finishes, check its output:

    ```
    cat hello.out
    ```

    Expect output similar to:

    ```
    Hello, World!
    I am running on hpc-worker123
    ```

If the job stays idle, make sure that your cluster's AP and EPs are successfully communicating:

```
condor_status
```

`hello.log` and `hello.err` may have more detail.
