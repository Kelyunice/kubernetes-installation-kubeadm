
Follow the instruction bellow to run the k8scp.sh script on the control plane

bash k8scp.sh | tee $HOME/cp.out

#this will save the output of the script in cp.out 


#Open a second terminal in your worker node to run the k8sworker.sh


bash k8sworker.sh | tee worker.out


#on the worker node run the kubeadm joint command generated from the control plane

kubectl get node
