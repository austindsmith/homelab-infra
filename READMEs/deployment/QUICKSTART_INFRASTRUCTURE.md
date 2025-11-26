# Quick Start Guide

Get your homelab infrastructure up and running in minutes.

## Prerequisites

- Proxmox VE installed and accessible
- Terraform installed on your local machine
- Ansible installed on your local machine
- kubectl installed on your local machine
- SSH key generated (`~/.ssh/id_ed25519`)

## Step 1: Create VMs with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Create the VMs
terraform apply

# Verify VMs are created
terraform output
```

This creates 3 Ubuntu VMs:
- lab-k8s-1 (192.168.50.15) - Server
- lab-k8s-2 (192.168.50.16) - Agent
- lab-k8s-3 (192.168.50.17) - Agent

## Step 2: Deploy K3s Cluster with Ansible

```bash
cd ../ansible

# Test connectivity
ansible all -m ping

# Deploy the cluster
./deploy.sh
```

This will:
- Update all systems
- Install K3s server on lab-k8s-1
- Install K3s agents on lab-k8s-2 and lab-k8s-3
- Configure networking
- Fetch kubeconfig

## Step 3: Configure kubectl

```bash
# Copy kubeconfig from server
scp root@192.168.50.15:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Update server IP
sed -i 's/127.0.0.1/192.168.50.15/g' ~/.kube/config

# Test connection
kubectl get nodes
```

You should see all 3 nodes in Ready state.

## Step 4: Validate Cluster

```bash
cd ansible

# Run validation
ansible-playbook validate-cluster.yml
```

## Step 5: Bootstrap ArgoCD

```bash
# Deploy ArgoCD
ansible-playbook applications/bootstrap-argocd.yml

# Get ArgoCD password
cat ~/.argocd-password
```

Access ArgoCD at: https://argo.theblacklodge.dev
- Username: admin
- Password: (from ~/.argocd-password)

## Step 6: Deploy Core Infrastructure

```bash
cd ../scripts

# Deploy core stack (Traefik, cert-manager)
./deploy-stack.sh core
```

## Step 7: Configure nginx-proxy-manager

In your nginx-proxy-manager (Docker):

1. Add Proxy Host:
   - Domain: `*.theblacklodge.dev`
   - Forward Hostname/IP: `192.168.50.15`
   - Forward Port: `80`
   - Enable "Websockets Support"
   - Enable "Block Common Exploits"

2. SSL Tab:
   - SSL Certificate: (Use your existing Cloudflare cert)
   - Force SSL: Yes
   - HTTP/2 Support: Yes

## Step 8: Deploy Data Lakehouse (Optional)

```bash
# Deploy datalake stack
./deploy-stack.sh datalake

# Monitor deployment
kubectl get pods -n datalake -w
```

## Common Commands

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl top nodes
```

### View ArgoCD Applications
```bash
kubectl get applications -n argocd
```

### Access Services Locally
```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Traefik Dashboard
kubectl port-forward svc/traefik -n traefik 9000:9000
```

### Deploy Individual Application
```bash
cd scripts
./deploy-app.sh minio
```

## Troubleshooting

### Nodes Not Ready
```bash
# Check node status
kubectl describe nodes

# Check kubelet logs
ssh root@192.168.50.15 "journalctl -u k3s -f"
```

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -A

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

### ArgoCD Not Accessible
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ingress
kubectl get ingress -n argocd

# Check Traefik
kubectl get svc -n traefik
```

### Certificate Issues
```bash
# Check certificates
kubectl get certificates -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## Next Steps

1. **Deploy Monitoring Stack**:
   ```bash
   ./deploy-stack.sh monitoring
   ```

2. **Deploy Applications**:
   ```bash
   ./deploy-app.sh homepage
   ./deploy-app.sh grafana
   ```

3. **Configure Cloudflare**:
   - Ensure DNS records point to your Cloudflare tunnel
   - Verify SSL/TLS settings

4. **Set Up Backups**:
   - Configure backup strategy for persistent data
   - Test restore procedures

5. **Implement Monitoring**:
   - Deploy Prometheus and Grafana
   - Set up alerts

## Access URLs

Once fully deployed:
- ArgoCD: https://argo.theblacklodge.dev
- Traefik Dashboard: https://traefik.theblacklodge.dev
- Grafana: https://grafana.theblacklodge.dev
- MinIO Console: https://minio-console.theblacklodge.dev
- Dremio: https://dremio.theblacklodge.dev
- JupyterHub: https://jupyter.theblacklodge.dev

## Getting Help

- Check documentation in `READMEs/` directory
- Review Ansible playbooks in `ansible/applications/`
- Examine Helm charts in `k8s/`
- Run validation: `ansible-playbook validate-cluster.yml`

## Complete Rebuild

If you need to start over:

```bash
# Destroy infrastructure
cd terraform
terraform destroy

# Start from Step 1
```

This quick start gets you from zero to a fully functional Kubernetes cluster with GitOps in about 30 minutes!

