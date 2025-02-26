#!/bin/bash

sudo kubeadm upgrade plan

sudo kubeadm upgrade apply v1.31.6 -y


kubectl drain $HOSTNAME --ignore-daemonsets

# Proceed to upgrade kubelet and kubectl version

sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet='1.31.6-1.1' kubectl='1.31.6-1.1' && sudo apt-mark hold kubelet kubect

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Proceed to uncordone node

kubectl uncordon $HOSTNAME

