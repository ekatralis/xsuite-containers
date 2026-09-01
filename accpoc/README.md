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

