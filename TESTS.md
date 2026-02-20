This README servers as preliminary documentation for how to run the container in a consistent fashion accross different OSes.
## Preliminary tests
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
Weirdly enough macOS is the most quirky one so far due to permission conflicts. I am able to fix the mounted drive permissions conflicts by running the container in this way, but this breaks access to the container file system
```bash
podman run --rm -it   --user 501:20   -v /Users/vkatralis/Documents/CERN/git/JUAS2026WorkshopStudents:/workspace   xsuite-test-build
```
Things to do:
- Debug permission issues
- Test on zsh