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
    echo "$FILE exists. Script has already been. Do not run on control plane."
    echo "This should be run on the worker node."
    echo
    exit 1
else
    echo "$FILE does not exist. Running  script"
fi


# Create a file when this script is started to keep it from running
# on the control plane node.
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
￼
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

# Install and configure crictl
export VER="v1.26.0"

wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VER/crictl-$VER-linux-amd64.tar.gz

tar zxvf crictl-$VER-linux-amd64.tar.gz

sudo mv crictl /usr/local/bin

# Set the endpoints to avoid the deprecation error
sudo crictl config --set \
runtime-endpoint=unix:///run/containerd/containerd.sock \
--set image-endpoint=unix:///run/containerd/containerd.sock


# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo "Use sudo and copy over kubeadm join command from"
echo "control plane."
echo
echo '***************************'
echo
echo

