#!/bin/bash
#
# This script is intended to be run on an Ubuntu 20.04,
# 2cpu, 8G.

# Note there is a lot of software downloaded, which may require
# some troubleshooting if any of the sites updates their code,
# which should be expected


# Check to see if the script has been run before. Exit out if so.
FILE=/k8scp_run
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been run on control plane."
    echo
    exit 1
else
    echo "$FILE does not exist. Running  script"
fi


# Create a file when this script is started to keep it from running
# twice on same node
sudo touch /k8scp_run

# Update the system
sudo apt-get update ; sudo apt-get upgrade -y

# Install necessary software
sudo apt-get install curl apt-transport-https vim git wget gnupg2 software-properties-common apt-transport-https ca-certificates -y

# Add repo for Kubernetes
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install the Kubernetes software, and lock the version
sudo apt-get update
sudo apt-get -y install kubelet=1.30.1-1.1 kubeadm=1.30.1-1.1 kubectl=1.30.1-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Ensure Kubelet is running
sudo systemctl enable --now kubelet

# Disable swap just in case
sudo swapoff -a

# Ensure Kernel has modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Update networking to allow traffic
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Configure containerd settings
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo sysctl --system

# Install the containerd software
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install containerd.io -y

# Configure containerd and restart
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd


#  Create the config file so no more errors
# Install and configure crictl
export VER="v1.26.0"

wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VER/crictl-$VER-linux-amd64.tar.gz

tar zxvf crictl-$VER-linux-amd64.tar.gz

sudo mv crictl /usr/local/bin

# Set the endpoints to avoid the deprecation error
sudo crictl config --set \
runtime-endpoint=unix:///run/containerd/containerd.sock \
--set image-endpoint=unix:///run/containerd/containerd.sock

# Configure the cluster
# This assumes you are not using 10.0.0.0/8 for your host. If your node network is in the same range you will lose connectivity to other nodes.
sudo kubeadm init --kubernetes-version=1.30.1 --pod-network-cidr=10.0.0.0/8  | sudo tee /var/log/kubeinit.log

# Configure the non-root user to use kubectl
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Use Cilium as the network plugin
# Install the CLI first
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
export CLI_ARCH=amd64

# Ensure correct architecture
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Make sure download worked
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

# Move binary to correct location and remove tarball
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Now that binary is in place, install network plugin
echo '********************************************************'
echo '********************************************************'
echo
echo Installing Cilium, this may take a bit...
echo
echo '********************************************************'
echo '********************************************************'
echo

cilium install

echo
sleep 3
echo Cilium install finished. Continuing with script.
echo


# Add Helm to make our life easier
wget https://get.helm.sh/helm-v3.11.1-linux-amd64.tar.gz
tar -xf helm-v3.11.1-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/

sleep 15

sudo crictl config --set \
runtime-endpoint=unix:///run/containerd/containerd.sock \
--set image-endpoint=unix:///run/containerd/containerd.sock


# Output the state of the cluster
kubectl get node

# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo '***************************'
echo

