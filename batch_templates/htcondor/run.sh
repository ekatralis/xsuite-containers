#!/usr/bin/env bash

CONTAINER_FULLPATH="/cvmfs/unpacked.cern.ch/ghcr.io/ekatralis/xsuite-containers:latest"
echo $CONTAINER_FULLPATH
containerrun() {
  apptainer exec \
    --env PYTHONNOUSERSITE=1 \
    --home "$_CONDOR_SCRATCH_DIR" \
    --writable-tmpfs \
    --cleanenv \
    $CONTAINER_FULLPATH \
    "$@"
}

# Optional: Print node info
echo "************************ NODE INFO *************************" 
hostname -A
hostname -I
lscpu
echo "*********************** END NODE INFO ***********************"

# Important: Print container version for future reference
echo "********************** CONTAINER INFO **********************"
containerrun bash -lc 'echo $XSUITE_CONTAINER_VERSION'
echo "******************** END CONTAINER INFO ********************" 

containerrun "$@"
