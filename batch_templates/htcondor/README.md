# Using Containers on HTCondor

This page describes how to best utilize containers when running simulation studies/parameter scans on HTCondor. One of the key use-cases for containers is 

## Why use containers?

This discussion will mainly revolve around HTCondor in CERN clusters (LxPlus) and how containers affect the workload on them. When running jobs on HTCondor, many people currently use a python environment they have set-up on the AFS filesystem which contains all the packages/dependencies required to run their job. When submitting hundreds/thousands of jobs at the same time, this creates unecessary load on AFS, which negatively affects the experience of other users, as such it is very common to hit a ceiling set from IT and be imposed a limit on the number of concurrent jobs you can run. 

Without using containers, there are two alternative approaches to navigating this issue:
- Using a ready-made environment from CVMFS and installing the packages required for every job during the job. This approach works for longer jobs where the installation time for the packages is negligible
- Using a ready-made environment on CVMFS, installing packages locally on EOS and copying the installed packages for every job. This is the **actual best** practice without using containers

The use of containers is an (in my opinion a bit more elegant) alternative to these options.

## Using Docker on HTCondor

It is possible to use Docker/Podman as the container engine on HTCondor. In this case each job pulls the container from the ghcr repository and runs the script inside the container. An example job script for that can be seen below:
```text
universe                = docker
docker_image            = registry.cern.ch/ghcr.io/ekatralis/xsuite-containers:latest
executable              = run.sh
arguments               = ./print_info.sh
transfer_input_files	= print_info.sh
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
output                  = out.$(ClusterId).$(ProcId)
error                   = err.$(ClusterId).$(ProcId)
log                     = log.$(ClusterId)
request_memory          = 1G
queue 1
```
In this case, I have configured a script called `run.sh`, which activates the virtual environment and ensures that the script `print_info.sh` runs inside the micromamba environment which is configured in the container. 

When running the container locally via podman/docker, packages can be installed into the container ephemerally via both micromamba and pip. Due to the way that the containers are run in the CERN clusters, the containers are mounted as read-only and cannot be modified, however, the `PATH` variable is appended with paths to your AFS local packages installation, which means that packages can be installed in the container, however they **will not** be ephemeral (or within the container). This can easily break python installations across jobs, so it is highly recommended to use the container as-is without modifying anything.

The main shortcoming of this approach is that there is no way to download the container locally and transfer it once for all jobs, this means that every job will re-download the container. This is fine for a small amount of jobs, however for jobs in the hundreds/thousands, it can easily result in rate-limiting from the container repository.

