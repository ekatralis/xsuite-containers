#!/usr/bin/env bash

CONTAINER_FULLPATH="/cvmfs/unpacked.cern.ch/ghcr.io/ekatralis/xsuite-containers:latest-cuda12.9"
containerrun() {
  apptainer exec \
    --env PYTHONNOUSERSITE=1 \
    --home "$_CONDOR_SCRATCH_DIR" \
    --writable-tmpfs \
    --cleanenv \
    --nv \
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
