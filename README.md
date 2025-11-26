## Terraforming Talos
Run this in either terraform/talos or terraform/ubuntu-server
```
terraform apply -auto-approve
```
Or to remove
```
terraform destroy -auto-approve
```
### Pushing talosconfig and kubeconfig to default locations (run from the terraform/talos directory)

```
terraform output -raw talosconfig > ~/.kube/talosconfig  
terraform output -raw kubeconfig > ~/.kube/config
```

### Export these locations as environmental variables (if that's how you want to handle it)
```
export TALOSCONFIG=$HOME/.kube/talosconfig       
export KUBECONFIG=$HOME/.kube/config
```
### Test the connection
```
kubectl get nodes
```

Once the cluster is deployed and connected to, switch to k8s for further deployment guidance.

## TODO
- [ ] Assign better variables for Talos Terraform and generally clean now that it's working
- [ ] Prune Docker services (transitioning to Kubernetes, so this is a low priority)
- [ ] Install and configure Rancher
- [ ] Migrate datalake applications
- [ ] Migrate other applications with existing databases so current configs and sessions are not lost
- [ ] Rework Terraform with newer provider versions
- [ ] Rework metallb with newer version
- [ ] Improve citations (proper format, include WayBackMachine archives)


## References

### Configuring Talos VMs through Terraform
https://olav.ninja/talos-cluster-on-proxmox-with-terraform

### Metallb load balancer installation
https://www.virtualizationhowto.com/2022/06/kubernetes-install-metallb-loadbalancer/

### Installing nginx-ingress

https://kubernetes.github.io/ingress-nginx/deploy/

## Note

I have found AI to be great and horrible. I started with it to build a Terraform/Ansible/k8s stack. This was super helpful because I was able to make headway quickly and understand the larger concepts at play faster because I was not buried in the weeds trying to understand each individual line.

Once I had something running in Ubuntu Server (it was terrible, barely ran and super buggy), I was ready to take on the deployment myself. Highly recommend using AI to generate initial files to understand the basic concepts like that. I plan to use that strategy more. Much easier to navigate the whole stack knowing generally what each part does and how they tie together.

However, AI can not replace a person (yet!) and makes awful mistakes. My goal with the deployment I'm documenting here is to not query AI once. Instead, I will try my best to develop using the actual documentation provided by the various vendors, and then look for a simplified guide as a last resort. This part is not only important to learning the concepts thoroughly, but I also do not want to become dependent on tools like AI.