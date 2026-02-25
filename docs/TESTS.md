This README servers as preliminary documentation for how to run the container in a consistent fashion accross different OSes.
## Preliminary tests
### Installing podman
Podman can be downloaded and installed from the website:
```bash
https://podman.io
```
On linux it can also be installed via package managers.
### Pulling the container
The container can be pulled using:
```bash
docker/podman pull registry.cern.ch/ekatrali/xsuite-containers/xsuite-jupyter
```
### Tests on Ubuntu using docker
Jupyterlab was working on Ubuntu out-of-the-box by simply building the container inside this repository and running:
```bash
sudo docker  run --rm --group-add=$(id -g) -it   -p 8888:8888   -v /home/edelafue/CAS-Transverse-Beam-Dynamics:/workspace  xsuite-test-build   bash -lc 'source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace'
```
Then visit the `127.0.0.0` ip and everything should work correctly
### Tests on Windows through Podman VM
Jupyterlab was able to run on Windows by installing podman and running:
From powershell run:
```bash
podman machine ssh
```
And then running:
```bash
podman run --rm --group-add=$(id -g) -it   -p 8888:8888   -v  /mnt/c/Users/edelafue/Documents/CAS-Transverse-Beam-Dynamics:/workspace  xsuite-test-build   bash -lc 'source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace'
```
Then by visiting the `127.0.0.0` ip from Windows and everything was working correctly. 
### Tests on Windows
Windows looks to be working by running:
```bash
podman run --rm -it   -p 8888:8888   -v  name-of-folder:/workspace  xsuite-test-build   bash -lc 'source /home/xsuiteuser/miniforge3/etc/profile.d/conda.sh && conda activate xsuite && exec jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir=/workspace'
```
Then by visiting the `127.0.0.0` ip everything was working correctly
### Tests on macOS
Running on macOS seems to work best by setting the home directory to be group-writeable, so that we can run as the macOS user to preserve read-write access to the workspace without breaking software inside the container.
```bash
podman run --rm -it   --user 501:20 --group-add 1001  -v /Users/vkatralis/Documents/CERN/git/JUAS2026WorkshopStudents:/workspace   xsuite-test-build
```
Things to do:
- Debug permission issues
- Test on zsh