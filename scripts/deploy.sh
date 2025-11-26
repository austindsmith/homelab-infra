#!/usr/bin/env bash
# deploy.sh - One-command deployment script for K3s cluster
# Usage: ./deploy.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl is not installed. Will be needed after deployment."
    fi
    
    log_success "Prerequisites check passed"
}

# Test connectivity
test_connectivity() {
    log_info "Testing connectivity to nodes..."
    
    if ansible all -m ping > /dev/null 2>&1; then
        log_success "All nodes are reachable"
    else
        log_error "Cannot reach all nodes. Please check your inventory and SSH keys."
        exit 1
    fi
}

# Main deployment
main() {
    echo "========================================="
    echo "  K3s Cluster Deployment Script"
    echo "========================================="
    echo ""
    
    check_prerequisites
    test_connectivity
    
    log_info "Starting deployment..."
    echo ""
    
    # Run main playbook
    log_info "Running Ansible playbook..."
    if ansible-playbook site.yml; then
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment failed. Check the output above for errors."
        exit 1
    fi
    
    echo ""
    echo "========================================="
    echo "  Deployment Complete!"
    echo "========================================="
    echo ""
    log_info "Next steps:"
    echo "  1. Copy kubeconfig: scp root@192.168.50.15:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
    echo "  2. Update server IP: sed -i 's/127.0.0.1/192.168.50.15/g' ~/.kube/config"
    echo "  3. Test cluster: kubectl get nodes"
    echo "  4. Deploy ArgoCD: ansible-playbook applications/bootstrap-argocd.yml"
    echo ""
}

# Run main function
main

