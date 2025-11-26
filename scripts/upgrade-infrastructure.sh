#!/bin/bash

# Infrastructure Upgrade Script
# Upgrades VM disk space and optimizes resource allocation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Infrastructure Upgrade Script"
echo "================================="
echo "This script will:"
echo "1. Update Terraform configuration for larger disks"
echo "2. Apply infrastructure changes"
echo "3. Optimize Kubernetes resource requests"
echo "4. Clean up cluster resources"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "$PROJECT_ROOT/terraform/main.tf" ]]; then
    log_error "Terraform configuration not found. Please run from project root."
    exit 1
fi

# Show current configuration
log_info "Current Terraform Configuration:"
cd "$PROJECT_ROOT/terraform"
terraform show -no-color | grep -E "(disk|memory|cores)" || echo "No current state found"

echo ""
log_warning "IMPORTANT: This will recreate your VMs with larger disks!"
log_warning "Current cluster data will be preserved via Ansible/Helm charts."
echo ""

read -p "Do you want to proceed with the infrastructure upgrade? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Upgrade cancelled."
    exit 0
fi

# Step 1: Terraform Plan
log_info "Step 1: Planning Terraform changes..."
terraform plan -out=upgrade.tfplan

echo ""
log_warning "Review the plan above. This will destroy and recreate VMs."
read -p "Apply these changes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Terraform apply cancelled."
    rm -f upgrade.tfplan
    exit 0
fi

# Step 2: Apply Terraform changes
log_info "Step 2: Applying Terraform changes..."
terraform apply upgrade.tfplan
rm -f upgrade.tfplan

# Step 3: Wait for VMs to be ready
log_info "Step 3: Waiting for VMs to be ready..."
sleep 30

# Step 4: Run Ansible to reconfigure cluster
log_info "Step 4: Reconfiguring K3s cluster with Ansible..."
cd "$PROJECT_ROOT/ansible"

# Check if ansible-playbook is available
if ! command -v ansible-playbook &> /dev/null; then
    log_warning "ansible-playbook not found. Trying to activate virtual environment..."
    if [[ -f "$HOME/venv/bin/activate" ]]; then
        source "$HOME/venv/bin/activate"
        log_info "Activated Python virtual environment"
    elif [[ -f "$PROJECT_ROOT/venv/bin/activate" ]]; then
        source "$PROJECT_ROOT/venv/bin/activate"
        log_info "Activated project virtual environment"
    else
        log_error "ansible-playbook not found and no virtual environment detected"
        log_error "Please install Ansible or activate your virtual environment"
        exit 1
    fi
fi

ansible-playbook site.yml

# Step 5: Deploy applications with optimized resources
log_info "Step 5: Deploying applications with optimized resource settings..."
cd "$PROJECT_ROOT"
./scripts/deploy-complete-stack.sh

# Step 6: Verify cluster health
log_info "Step 6: Verifying cluster health..."
export KUBECONFIG=~/.kube/config
kubectl get nodes
kubectl get pods -A | grep -E "(Running|Ready)"

log_success "Infrastructure upgrade completed successfully!"
echo ""
echo "📊 New VM Specifications:"
terraform output vm_specs
echo ""
echo "🌐 Access your services at:"
echo "   Homepage: https://homepage.theblacklodge.dev"
echo "   ArgoCD: https://argo.theblacklodge.dev"
echo ""
echo "📝 Next steps:"
echo "   1. Update nginx-proxy-manager configurations if needed"
echo "   2. Test all services are accessible"
echo "   3. Monitor cluster resource usage"
