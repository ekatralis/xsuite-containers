# Using Xsuite Containers with AccPOC 
This page describes how to use xsuite-containers with the AccPoC Kubernetes Cluster at CERN. The key advantage that this approach presents is that it enables a consistent experience from development to batch jobs, as the user can test scripts and simulations in the exact same environment that their jobs will run in. 

## One-time setup
The scripts used to set up the notebooks require the `kubectl` CLI tool to be installed and configured appropriately. It is therefore recommended to use `lxplus` for this, as the `kubectl` plugin is installed and configured. If you want to do the same from a different machine that is connected to the CERN network, refer to the section.

From `lxplus` run the following commands:
```bash
mkdir -p ~/.kube
wget -O ~/.kube/config https://accpoc-public.web.cern.ch/config
kubectl config use-context accpoc
```
These configure your `kubectl` plugin to point to the AccPOC cluster.

## Configuring a notebook
To set up a notebook using xsuite-containers on AccPoC follow these steps:
- Visit https://accpoc.cern.ch/ and click on **Notebooks** and then **+ New Notebook**
- Name the notebook (name cannot contain "_" and spaces, only "-"). Leave the rest of the options to default.
- Select the desired CPU or GPU flavor (Number of CPUs/GPUs and corresponding RAM capacity) depending on your workload.
- Click on **Custom Notebook**, then **Advanced Options**, and then tick the **Custom Image** box.
  - For GPU notebooks use:
    ```text
    ghcr.io/ekatralis/xsuite-containers:latest-cuda
    ```
  - For CPU only notebooks use:
    ```text
    ghcr.io/ekatralis/xsuite-containers:latest
    ```
- Launch the notebook
- Clone the repository and go into the `accpoc` directory:
  ```bash
  git clone https://github.com/ekatralis/xsuite-containers.git
  cd xsuite-containers/accpoc 
  ```
  or download the script and make it executable:
  ```bash
  wget https://raw.githubusercontent.com/ekatralis/xsuite-containers/refs/heads/main/accpoc/accpoc-configure-xsuite
  chmod +x accpoc-configure-xsuite
  ```
- Run the script with the notebook name as the only argument:
  ```bash
  ./accpoc-configure-xsuite <notebook-name>
  ```
- You can then access the notebook either through `ssh` or throught the web UI.

While running the script you might encounter the following prompt:
```text
Please visit the following URL in your browser: https://auth.cern.ch/auth/realms/cern/protocol/openid-connect/auth?...
Enter code:
```
This is used to authenticate with the cluster, so simply copy the link in your browser, paste the code you get into your terminal and click enter.

## Setting up kubectl locally (Optional)
On Linux, you can download the `kubectl` executable using:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
Accessing AccPoC also requires `kubelogin`, which can be installed using:
```bash
curl -LO \
  https://github.com/int128/kubelogin/releases/download/v1.32.2/kubelogin_linux_amd64.zip
unzip -o kubelogin_linux_amd64.zip
sudo install -m 0755 kubelogin /usr/local/bin/kubectl-oidc_login
```

