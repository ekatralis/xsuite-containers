FROM ubuntu:24.04
# Could try debian:bookworm-slim

# Non-root user for safety UID and GID outside of typical range to avoid conflicts with host users
# Supposed to use --user when running container to map to host user
ARG UID=2020
ARG GID=2020

RUN groupadd -g ${GID} xsuiteuser \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash xsuiteuser

WORKDIR /home/xsuiteuser

# Install system dependencies while still in root 
RUN apt-get update && \
    apt-get install -y wget bzip2 ca-certificates curl git gcc && \ 
    rm -rf /var/lib/apt/lists/*

RUN chown -R xsuiteuser:xsuiteuser /home/xsuiteuser && \
    chmod 2775 /home/xsuiteuser && \
    umask 002 && \
    mkdir -p /home/xsuiteuser/.cache

# Switch to user for Miniforge setup and subsequent steps
USER xsuiteuser

# Install Miniforge (x86_64)
ENV MINIFORGE_VERSION=latest
ENV CONDA_DIR=/home/xsuiteuser/miniforge3
RUN set -eux; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
        x86_64|amd64)  MF_ARCH="x86_64" ;; \
        aarch64|arm64) MF_ARCH="aarch64" ;; \
        *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac; \
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${MF_ARCH}.sh -O /tmp/miniforge.sh; \
    bash /tmp/miniforge.sh -b -p $CONDA_DIR; \
    rm /tmp/miniforge.sh 

# Activate environment by default
SHELL ["conda", "run", "-n", "xsuite", "/bin/bash", "-c"]

# Install pip packages (example)
ENV PATH=$CONDA_DIR/bin:$PATH \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN conda create -y -n xsuite python=3.11 && \
    conda install -c conda-forge -y -n xsuite mpi4py h5py && \
    conda run -n xsuite pip install xsuite["full_env"]==0.45.5 && \
    conda run -n xsuite pip install xwakes['tests'] && \
    conda clean -afy
# Uncomment for development version
# RUN mkdir -p /home/xsuiteuser/.packages && \
#     cd /home/xsuiteuser/.packages && \
#     git clone https://github.com/xsuite/xobjects && \
#     git clone https://github.com/xsuite/xdeps && \
#     git clone https://github.com/xsuite/xpart && \
#     git clone https://github.com/xsuite/xtrack && \
#     git clone https://github.com/xsuite/xfields && \
#     git clone https://github.com/xsuite/xwakes && \
#     git clone https://github.com/xsuite/xcoll


RUN conda init bash
RUN echo 'conda activate xsuite' >> /home/xsuiteuser/.bashrc
# RUN echo 'umask 002' >> /home/xsuiteuser/.bashrc

# Make dirs setgid + group writable
# RUN find /home/xsuiteuser -type d -exec chmod g+rws {} + && \
#     # Make everything group readable/writable, but preserve executability
#     find /home/xsuiteuser -exec chmod g+rwX {} +