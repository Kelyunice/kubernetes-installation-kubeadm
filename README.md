
Follow the instruction bellow to run the k8scp.sh script on the control plane

bash k8scp.sh | tee $HOME/cp.out

#this will save the output of the script in cp.out 


#Open a second terminal in your worker node to run the k8sworker.sh


bash k8sworker.sh | tee worker.out


#on the worker node run the kubeadm joint command generated from the control plane

kubectl get node


=================================================================================================================================================================================================

 check which operating system is your cluster running on
 cat /etc/os-releases
 check the k8s version you are actually using
 kubectl get node (major release, minor release, patch version)
 when upgarding, the API-server should be at the same  minor version or highest version than the scheduler and the controller manager.The kubelet can be 2 versions behind the API-server

  1- Upgrade a primary control plane node.
  2- Upgrade additional control plane nodes.
  3- Upgrade worker nodes

  cat /etc/os-release
  pager /etc/apt/sources.list.d/kubernetes.list

  To confirm the upgrade check in the manifest file of the static node

  /etc/kubernetes/manifests

  if you have another master node Run
 
  sudo kubeadm upgrade node

  Proceed to DRAIN THE NODE

