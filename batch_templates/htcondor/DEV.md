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

```
ll /afs/cern.ch/user/e/ekatrali/.local/lib/python3.11/site-packages
```

## Using Apptainer on HTCondor

This brings us to the best/most HPC native container flavor. Apptainer (fork of Singularity maintained by the Linux Foundation) is an HPC native way of running containers on HPC systems. It doesn't have the same layer structure as docker containers and as such the resulting containers are usually much smaller in size. A key difference when running Apptainer containers is that by default, they don't provide a writeable overlay and as such they are read-only. In addition, by default the home directory is mounted and the `PATH` variable inside the container is appended to include the user's home directory for local installs. 

### A bit of background
To run jobs inside Apptainer containers, the current [documentation](https://batchdocs.web.cern.ch/containers/singularity.html) suggests the following submission file:
```text
executable              = runme.sh
log                     = singularity.$(ClusterId).log
error                   = singularity.$(ClusterId).$(ProcId).err
output                  = singularity.$(ClusterId).$(ProcId).out
should_transfer_files   = YES
MY.JobFlavour           = "longlunch"
transfer_input_files    = root://eosuser.cern.ch//eos/user/b/bejones/scripts/payload.py, root://eosuser.cern.ch//eos/user/b/bejones/data/input.txt
output_destination      = root://eosuser.cern.ch//eos/user/b/bejones/results/$(ClusterId)/
transfer_output_files   = output.txt
MY.XRDCP_CREATE_DIR     = True
MY.SingularityImage     = "/cvmfs/unpacked.cern.ch/gitlab-registry.cern.ch/batch-team/containers/plusbatch/cs8-full:latest"
queue
```
However, as you may have guessed from the previous comments, this has one very big flaw: It mounts your AFS home as the container `$HOME` by default, which can create several issues if your scripts happen to use the home directory for caching (for example).

### How to actually use Apptainer on HTCondor
The following documentation describes how to use the containers defined in this repository. If you have created your own custom definitions, the process should be very similar, however you may need to slightly adapt the commands to your use case.

To build the container, you can use your desired definition. From inside the main folder of this repository run:
```bash
apptainer build xsuitecontainer.sif Apptainer-{full,slim}.sif
```
The above command will generate a `.sif` container in your local repository. If you want to inspect the container by running a shell inside it you can run:
```bash
apptainer exec xsuitecontainer.sif bash
```
Now that we have created a local container image, we can define our executable, which we can unimaginatively name `executable.sh`:
```bash
#!/usr/bin/env bash

containerrun() {
  apptainer exec \
    --env PYTHONNOUSERSITE=1 \
    --home "$_CONDOR_SCRATCH_DIR" \
    --writable-tmpfs \
    --cleanenv \
    xsuitecontainer.sif \
    "$@"
}

containerrun python script.py
```
> [!IMPORTANT]
> Containers are *isolated environments* and sessions are ephemeral. Any environment variables you set in this script *will not* be transferred to the script. 
> Commands run under previous `containerrun` commands *do not* carry over to other runs.

The `containerrun` function simply runs the `apptainer exec` with some default options which are best-suited for usage on HTCondor:
- `--env PYTHONNOUSERSITE=1`: This ensures that no packages are being shadowed by packages installed locally on AFS. (Note: There should be no leakage from AFS given that we subsequently mount the condor scratch directory as the home for the container, but it is a good practice)
- `--home "$_CONDOR_SCRATCH_DIR"`: Mounts the local condor scratch directory as `HOME` inside the container. This directory is emptied after a job has finished. This ensures that no files are accidentally spilling over from the container to AFS.
- `--writable-tmpfs`: This introduces a small 64MB temporary writeable layer over the container filesystem. It ensures that jobs cannot crash if a package tries to create a small file inside the container. This is not intended to be used to perform temporary modifications to the container (such as install additional packages to the container. For that see below).
- `--cleanenv`: Ensures that environment variables from the main environment (or `.bashrc`) are not accidentally being transfered inside the container
- `xsuitecontainer.sif`: The container name. If you are using a different container replace it with the desired container.

If you already have a job script that you want to use, you can simply wrap that script like so:
```bash
#!/usr/bin/env bash

containerrun() {
  apptainer exec \
    --env PYTHONNOUSERSITE=1 \
    --home "$_CONDOR_SCRATCH_DIR" \
    --writable-tmpfs \
    --cleanenv \
    xsuitecontainer.sif \
    "$@"
}

containerrun yourscript.sh
```
In this case you have to ensure that your script is already executable (`chmod +x yourscript.sh`). 

For the setup described above our sample submission script becomes:
```text
executable              = executable.sh
arguments               = ""
transfer_input_files	= xsuitecontainer.sif, yourscript.sh
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
output                  = out.$(ClusterId).$(ProcId)
error                   = err.$(ClusterId).$(ProcId)
log                     = log.$(ClusterId)
queue 1
```
We have to ensure that we use the `transfer_input_files` argument to transfer both our container and our executable script when submitting the job.

### How to modify container for custom packages
The goal of this repository is to provide containers which are ready-to-use, as such if you find that an important package is missing, please open and issue to see if it can be included in the next release. However, it is often the case that you need to install your own custom packages, or modified versions of existing packages. In this case, two different approaches can be used.

#### Approach to package management inside the container
- **Recommended approach**: The container ship with a main `micromamba` environment installed under `/home/xsuiteuser/xsuite-env`. It is recommended to use `micromamba` and `pip` inside that environment to manage packages and dependencies. `micromamba` shares the same interface as `conda`, as you can proceed as you would as if you were inside a `conda` environment
- The base OS for the container is Ubuntu, so you can technically install packages using `apt-get`. While this way of installing packages is supported when using Apptainer, it is recommended to try the `micromamba` route first.

#### Modify the container definition
The Apptainer container definitions can be found in the `.def` files in the main directory of this repository. In the following example, we will replace one of the python packages with our own fork to test out changes. This example can also be found under `example_customize` as well.
```text
Bootstrap: docker
From: ghcr.io/ekatralis/xsuite-containers:latest

%post
    # Set path to environment for convenience
    ENV_PREFIX="/home/xsuiteuser/xsuite-env"

    # Install any packages inside /home/xsuiteuser
    mkdir -p /home/xsuiteuser/packages
    cd /home/xsuiteuser/packages/

    # Clone a custom package that requires compilation + cmake
    git clone --recursive https://github.com/ekatralis/PyKLU.git
    cd ./PyKLU
    # Install cmake from conda-forge
    micromamba install -y -p "$ENV_PREFIX" -c conda-forge cmake
    # Install package, ensure that we use micromamba run to stay inside the environment
    micromamba run -p "$ENV_PREFIX" pip install -e .
    cd ..

    # Clone our custom package
    git clone https://github.com/ekatralis/xobjects.git
    cd ./xobjects
    git switch AddSparseSolvers # Switch to working branch
    micromamba run -p "$ENV_PREFIX" pip install -e .[sparse] # include dependencies

%environment
    # Unset BASH_ENV for Apptainer, as micromamba is read-only and cannot write to it. 
    unset BASH_ENV
    export PYTHONNOUSERSITE=1
```
Then we can build this container by running:
```bash
apptainer build xsuitecontainer.sif Apptainer-custom.def
```
The resulting container can be used exactly as described before.
#### Use an editable overlay

