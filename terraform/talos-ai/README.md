# Talos Linux Terraform Configuration

This directory contains Terraform configurations for deploying Talos Linux VMs as an alternative to Ubuntu-based K3s.

## Files

- `main-talos.tf` - Full production Talos deployment
- `main-talos-trial.tf` - Minimal trial deployment (for testing)
- `variables-talos.tf` - Production variables
- `variables-talos-trial.tf` - Trial variables
- `terraform-talos-trial.tfvars` - Trial configuration values

## Why Talos?

Talos Linux is an immutable, API-driven OS designed specifically for Kubernetes:
- **Memory Savings**: ~200MB RAM vs Ubuntu's ~1GB+ per node
- **Security**: Immutable OS, no SSH, smaller attack surface
- **Simplicity**: API-driven, no manual configuration

## Deployment Options

### Option 1: Production Deployment

Replaces your existing K3s infrastructure with Talos:

```bash
cd terraform/talos
terraform init
terraform plan -var-file="main-talos.tfvars"
terraform apply -var-file="main-talos.tfvars"
```

**Resources**: 3 VMs with 8GB RAM, 4 cores, 100GB disk each

### Option 2: Trial Deployment

Runs alongside existing K3s for testing:

```bash
cd terraform/talos
terraform init
terraform plan -var-file="terraform-talos-trial.tfvars"
terraform apply -var-file="terraform-talos-trial.tfvars"
```

**Resources**: 3 VMs with 2GB RAM, 2 cores, 20GB disk each

## Prerequisites

1. **Create Talos Template in Proxmox**:
   - Download Talos ISO from https://github.com/siderolabs/talos/releases
   - Create VM with ID 9001
   - Install Talos from ISO
   - Convert to template: `qm template 9001`
   - Rename to `talos-template`

2. **Install talosctl**:
   ```bash
   curl -sL https://talos.dev/install | sh
   ```

## Post-Deployment Configuration

After VMs are created, configure Talos:

```bash
# Generate configuration
talosctl gen config talos-cluster https://192.168.50.15:6443 \
    --output-dir talos-config

# Apply to control plane
talosctl apply-config --insecure \
    --nodes 192.168.50.15 \
    --file talos-config/controlplane.yaml

# Apply to workers
talosctl apply-config --insecure \
    --nodes 192.168.50.16,192.168.50.17 \
    --file talos-config/worker.yaml

# Bootstrap cluster
talosctl bootstrap --nodes 192.168.50.15

# Get kubeconfig
talosctl kubeconfig --nodes 192.168.50.15
```

## Network Configuration

### Production Deployment
- IPs: 192.168.50.15-17
- VMIDs: 2000-2002
- **Note**: Conflicts with existing K3s infrastructure

### Trial Deployment
- IPs: 192.168.50.100-102
- VMIDs: 9100-9102
- Runs alongside existing K3s

## Cleanup

```bash
# Destroy trial VMs
cd terraform/talos
terraform destroy -var-file="terraform-talos-trial.tfvars"

# Destroy production VMs
terraform destroy -var-file="main-talos.tfvars"
```

## Documentation

For complete migration guide, see: [READMEs/infrastructure/TALOS_MIGRATION.md](../../READMEs/infrastructure/TALOS_MIGRATION.md)

## Notes

- Talos requires configuration before networking is active
- VMs won't respond to ping until configured with talosctl
- No SSH access - all management via Talos API
- Kubernetes is included but not configured until bootstrap

