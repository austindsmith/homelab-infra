# Talos Linux Migration Guide

## Overview

This guide covers migrating from Ubuntu-based K3s to Talos Linux for improved resource efficiency and security.

## Why Talos Linux?

**Memory Savings:**
- **Ubuntu**: ~1GB+ RAM per node for OS = ~3GB total
- **Talos**: ~200MB RAM per node for OS = ~600MB total
- **Net Savings**: ~2.5GB RAM freed up for applications!

**Additional Benefits:**
- Immutable OS (more secure)
- API-driven (no SSH needed)
- Designed specifically for Kubernetes
- Faster boot times
- Smaller attack surface

## Prerequisites

- Proxmox server with available resources
- Existing K3s cluster (optional - can run alongside)
- Basic understanding of Kubernetes

## Step 1: Create Talos Template in Proxmox

1. **Download Talos ISO:**
```bash
wget https://github.com/siderolabs/talos/releases/download/v1.7.6/talos-amd64.iso
```

2. **Create VM Template in Proxmox:**
   - Create new VM with ID 9001
   - Use the Talos ISO
   - Configure: 2GB RAM, 32GB disk, 2 CPU cores
   - Boot from ISO and let it install
   - Convert to template: `qm template 9001`
   - Rename template to `talos-template`

## Step 2: Deploy Talos VMs

The Terraform configuration is located in `terraform/talos/`.

### Option A: Full Production Deployment

```bash
cd terraform/talos
terraform init
terraform plan -var-file="main-talos.tfvars"
terraform apply -var-file="main-talos.tfvars"
```

This creates 3 VMs with production resources:
- 8GB RAM, 4 cores, 100GB disk each
- IPs: 192.168.50.15-17
- VMIDs: 2000-2002

### Option B: Trial Deployment (Alongside K3s)

```bash
cd terraform/talos
terraform init
terraform plan -var-file="trial.tfvars"
terraform apply -var-file="trial.tfvars"
```

This creates 3 minimal VMs for testing:
- 2GB RAM, 2 cores, 20GB disk each
- IPs: 192.168.50.100-102
- VMIDs: 9100-9102

## Step 3: Configure Talos

1. **Install talosctl CLI:**
```bash
curl -sL https://talos.dev/install | sh
```

2. **Generate Talos Configuration:**
```bash
talosctl gen config talos-cluster https://192.168.50.15:6443 \
    --output-dir talos-config
```

3. **Apply Configuration to Control Plane:**
```bash
talosctl apply-config --insecure \
    --nodes 192.168.50.15 \
    --file talos-config/controlplane.yaml
```

4. **Apply Configuration to Workers:**
```bash
talosctl apply-config --insecure \
    --nodes 192.168.50.16 \
    --file talos-config/worker.yaml

talosctl apply-config --insecure \
    --nodes 192.168.50.17 \
    --file talos-config/worker.yaml
```

## Step 4: Bootstrap Kubernetes

```bash
# Bootstrap the cluster
talosctl bootstrap --nodes 192.168.50.15

# Wait for cluster to be ready (2-3 minutes)
talosctl --nodes 192.168.50.15 health

# Get kubeconfig
talosctl kubeconfig --nodes 192.168.50.15
```

## Step 5: Verify Cluster

```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A

# Verify all nodes are ready
kubectl get nodes -o wide
```

## Step 6: Migrate Workloads (If Applicable)

If migrating from existing K3s:

1. **Export current workloads:**
```bash
kubectl get all -A -o yaml > k8s-backup.yaml
```

2. **Apply to new cluster:**
```bash
kubectl apply -f k8s-backup.yaml
```

3. **Verify applications:**
```bash
kubectl get pods -A
```

## Step 7: Cleanup Old Infrastructure

Once verified, destroy old K3s VMs:

```bash
cd terraform
terraform destroy -target=proxmox_vm_qemu.k3s_vm
```

## Troubleshooting

### VMs Not Responding
- Talos requires configuration before networking is active
- Check VM console in Proxmox
- Verify template was created correctly

### Configuration Not Applying
```bash
# Check Talos service status
talosctl --nodes <IP> service

# View logs
talosctl --nodes <IP> logs kubelet
```

### Cluster Not Bootstrapping
```bash
# Check etcd status
talosctl --nodes 192.168.50.15 etcd members

# Reset if needed
talosctl reset --nodes <IP> --graceful=false
```

## Resource Comparison

| Setup | VMs | Total RAM | Total CPU | Total Disk |
|-------|-----|-----------|-----------|------------|
| Ubuntu K3s | 3 | 24GB | 12 cores | 300GB |
| Talos Production | 3 | 24GB | 12 cores | 300GB |
| Talos Trial | 3 | 6GB | 6 cores | 60GB |

**Note:** Same resources but Talos uses ~2.5GB less RAM for OS overhead!

## Files and Locations

- **Terraform**: `terraform/talos/`
- **Trial Results**: `/tmp/talos-trial.log`
- **Talos Config**: Generated in `talos-config/` directory
- **Kubeconfig**: `~/.kube/config`

## Additional Resources

- [Talos Documentation](https://www.talos.dev/docs/)
- [Talos GitHub](https://github.com/siderolabs/talos)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

