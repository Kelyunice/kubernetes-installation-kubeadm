#!/bin/bash


#sed -i "s/30/31" /etc/apt/sources.list.d/kubernetes.list

sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.31.6-1.1*' && sudo apt-mark hold kubeadm

sudo kubeadm upgrade node

# PROCEED TO DRAIN NODE (RUN THE COMMAND ON THE MASTER NODE)

kubectl drain $HOSTNAME --ignore-daemonsets

sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.31.6-1.1' kubectl='1.31.6-1.1' && sudo apt-mark hold kubelet kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo "run the command below on the master node"

echo 

echo "kubectl uncordon <worker-node-name>"
