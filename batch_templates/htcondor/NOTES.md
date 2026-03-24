Apptainer also supports the use of editable overlays on top of the container. Using an editable overlay allows you to interactively edit the container and include your desired packages. You can create an overlay using:
```bash
apptainer overlay create --size 1024 --sparse my_overlay.img 
```
This will create an overlay with a maximum size of 1GB, if your packages require more, then increase the size. The `--sparse` flag, ensures that the overlay doesn't immediately consume the entire 1GB that is available and it is only consumed as you install packages. Then run the container using:
```bash
apptainer shell --overlay my_overlay.img my_container.sif
```
Then you have an interactive shell from which you can install all the required packages. To install the packages, you must first activate the environment which can be done by running:
```bash
source /home/xsuiteuser/.bash_env_mamba
```
Then you can install away using `pip`, `micromamba` and (preferrably as a last resort) `apt`. 

apptainer shell --home $PWD xsuite-test.sif 
apptainer exec --home=$(pwd) xsuite-full.sif bash
echo $_CONDOR_SCRATCH_DIR

apptainer shell --env PYTHONNOUSERSITE=1 --home $PWD xsuite-full.sif 
apptainer shell --env PYTHONNOUSERSITE=1 --home $PWD --writable-tmpfs xsuite-full.sif

alias containerrun='apptainer exec --env PYTHONNOUSERSITE=1 --home $_CONDOR_SCRATCH_DIR --cleanenv xsuite-full.sif'

```bash
#!/usr/bin/env bash

CONTAINER_FULLPATH="$_CONDOR_SCRATCH_DIR/xsuitecontainer.sif"
echo $CONTAINER_FULLPATH
containerrun() {
  apptainer exec \
    --home "$_CONDOR_SCRATCH_DIR" \
    --writable-tmpfs \
    --cleanenv \
    $CONTAINER_FULLPATH \
    "$@"
}

containerrun "$@"

```