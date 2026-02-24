# Unify container building and running process

## How to build
Depending on the target build architecture, the containers can be built using the following instructions:
```bash
podman build --arch arm64 -t xsuite-test-build .
podman build --arch amd64 -t xsuite-test-build .
```
## How to run
```bash
# On MacOS
podman run --rm -it   --user $(id -u):$(id -g) --group-add 2020  -v /Users/vkatralis/Documents/CERN/git/JUAS2026WorkshopStudents:/workspace   xsuite-test-build
# On Linux/Windows
podman run --rm -it   --userns=keep-id  -v /home/evangeloskatralis/Documents/git/CAS-Transverse-Beam-Dynamics:/workspace   xsuite-test-build
```