#!/bin/bash
# Deploy Talos Trial VMs alongside existing k3s infrastructure
# This script deploys minimal Talos VMs for testing without affecting k3s

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/talos-trial"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

echo "=========================================="
echo "Talos Trial Deployment"
echo "=========================================="
echo ""
echo "This will create 3 minimal Talos VMs:"
echo "  - talos-trial-01: 192.168.50.25 (VMID 9101) - 2GB RAM, 2 cores"
echo "  - talos-trial-02: 192.168.50.26 (VMID 9102) - 2GB RAM, 2 cores"
echo "  - talos-trial-03: 192.168.50.27 (VMID 9103) - 2GB RAM, 2 cores"
echo ""
echo "Your existing k3s VMs (192.168.50.15-17) will NOT be affected!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 1: Initialize Terraform
echo ""
echo "Step 1: Initializing Terraform..."
cd "$TERRAFORM_DIR"
terraform init

# Step 2: Plan deployment
echo ""
echo "Step 2: Planning Talos VM deployment..."
terraform plan -out=talos-trial.tfplan

echo ""
echo "Review the plan above. This will create 3 new VMs."
read -p "Apply this plan? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    rm -f talos-trial.tfplan
    exit 0
fi

# Step 3: Apply Terraform
echo ""
echo "Step 3: Creating Talos VMs..."
terraform apply talos-trial.tfplan
rm -f talos-trial.tfplan

# Step 4: Wait for VMs to boot
echo ""
echo "Step 4: Waiting for VMs to boot (30 seconds)..."
sleep 30

# Step 5: Validate with Ansible
echo ""
echo "Step 5: Validating VM connectivity..."
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory-talos-trial.ini talos-trial-validate.yml

echo ""
echo "=========================================="
echo "Talos Trial Deployment Complete!"
echo "=========================================="
echo ""
echo "VMs are running at:"
echo "  - talos-trial-01: 192.168.50.25"
echo "  - talos-trial-02: 192.168.50.26"
echo "  - talos-trial-03: 192.168.50.27"
echo ""
echo "Next steps:"
echo "  1. Install talosctl: curl -sL https://talos.dev/install | sh"
echo "  2. Check VM status in Proxmox UI"
echo "  3. When ready, configure Talos and bootstrap Kubernetes"
echo ""
echo "To destroy these VMs:"
echo "  cd $TERRAFORM_DIR"
echo "  terraform destroy"
echo ""

