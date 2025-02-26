#!/bin/bash
#check which operating system is your cluster running on
# cat /etc/os-releases
# check the k8s version you are actually using
# kubectl get node (major release, minor release, patch version)
# when upgarding, the API server must be at the minor version or highest version than the kubelet and the controller manager.The kubelet can be 2 versions behind (controller manager and the scheduler)
# 
# 1- Upgrade a primary control plane node.
# 2- Upgrade additional control plane nodes.
# 3- Upgrade worker nodes
# 
# cat /etc/os-release
# pager /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt-cache madison kubeadm

sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.31.6-1.1' && sudo apt-mark hold kubeadm

# kubeadm version

sudo kubadm upgrade plan

sudo kubeadm upgrade apply v1.31.6 -y

# To confirm the upgrade check in the manifest file of the static node
# 
# /etc/kubernetes/manifests
#
# if you have another master node Run 
#
# sudo kubeadm upgrade node

# Proceed to DRAIN THE NODE

kubectl drain <node-to-drain> --ignore-daemonsets

# Proceed to upgrade kubelet and kubectl version

sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.31.6-1.1' kubectl='1.31.6-1.1' && sudo apt-mark hold kubelet kubect

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Proceed to uncordone node

kubectl uncordon <node-to-uncordon>

# Proceed to upgrade the worker node ( RUN THIS ON THE WORKER NODE)

# pager /etc/apt/sources.list.d/kubernetes.list

sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm='1.31.6-1.1*' && sudo apt-mark hold kubeadm

sudo kubeadm upgrade node

# PROCEED TO DRAIN NODE (RUN THE COMMAND ON THE MASTER NODE)

kubectl drain <node-to-drain> --ignore-daemonsets

# RUN ON WORKER 
# sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.31.6-1.1' kubectl='1.31.6-1.1' && sudo apt-mark hold kubelet kubectl
#
# sudo systemctl daemon-reload
# sudo systemctl restart kubelet
#
# RUN ON MASTER
#
# kubectl uncordon <node-to-uncordon>
