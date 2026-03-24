# Using Containers on HTCondor

This purpose of this documentation is to explain how to run xsuite simulations using the containers defined in this repository on CERN's cluster using HTCondor. 
## Parameter Scan
On CERN clusters, the container is published on `cvmfs` under the path:
```text
/cvmfs/unpacked.cern.ch/ghcr.io/ekatralis/xsuite-containers\:{tags}
```
with the exact same tagging logic as the podman/docker images in this repository.

Inside this `htcondor` directory, you can find two wrapper scripts, which can be used to run scripts/simulations inside the latest version of the container on both CPU and GPU. The script simply runs any commands that follow after it inside the container, so it can be used as in the following examples:
```bash
# For CPU
./run.sh ./your_old_script.sh
./run.sh python simulation.py
# For GPU
./run_gpu.sh ./your_old_script.sh
./run_gpu.sh python simulation.py
```
> [!IMPORTANT]
> If you run a script inside the container, ensure that it is **not** creating/sourcing any python environment. A full python environment already exists 
> inside the container, and this is the environment that's intended to be used. Also ensure that you only set environment variables relevant for your scripts.

You can inspect and modify them to your usecase if you so desire. In case you modify the scripts, it is highly recommended to add a line that prints the environment variable inside the container:
```text
XSUITE_CONTAINER_VERSION
```
As this can be used to immediately reproduce any simulation you previously ran.

An example submission `htcondor.sub` can be found inside the `htcondor` directory as well. This shows how you can structure your submit file to run a python file inside the container and send the output to `EOS`.

#### Example
Under `example` you can find an example of such a parameter scan if you want to experiment or use as a template. The example can be run as follows:
- Run `python3 setup_paramscan.py` to set up all the experiments we will be running
- Run `condor_submit htcondor.sub` to submit all the jobs

This example was taken from https://github.com/ekatralis/xsuite-containers-demo, which was in turn an adapted example of https://github.com/ImpedanCEI/CAS-Transverse-Beam-Dynamics. 

## Modifying the container

The container is meant to be used as-is, but under special circumstances, it is possible to modify the container. A detailed guide for this will be published soon, but the tldr version is **use Apptainer overlays**:
- Create overlay directory on EOS
- Launch bash inside container from CVMFS with overlay applied
- Install packages in overlay
    - Recommended not to install in editable mode
    - Install package via pip, then remove repository since git repos often contain tests/docs which add unnecessary bulk to the overlay
- Once done exit container
- Compress overlay into a single file
- Include overlay in files to be transferred from EOS for every job
- Append flags in run.sh script to apply the overlay

## Useful links
Presentation at the ABP-CAP meeting: https://indico.cern.ch/event/1657344/  
GitHub repo of containers demo: https://github.com/ekatralis/xsuite-containers-demo
The `DEV.md` file documents some experiments I performed while investigating the best practices. Feel free to consult this document as well