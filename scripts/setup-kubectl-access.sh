#!/bin/bash

# Setup kubectl Access to K3s Cluster
# This script helps you get kubectl access to your k3s cluster

set -e

echo "=== Setting up kubectl access to K3s cluster ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# K3s server details from inventory
K3S_SERVER="192.168.50.15"
K3S_USER="austin"

echo "Attempting to fetch kubeconfig from K3s server..."
echo "Server: $K3S_SERVER"
echo "User: $K3S_USER"
echo ""

# Check if we can SSH to the server
print_status "Testing SSH connection..."

if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${K3S_USER}@${K3S_SERVER} "echo 'SSH connection successful'" 2>/dev/null; then
    print_status "SSH connection successful!"
    
    # Fetch kubeconfig
    print_status "Fetching kubeconfig from server..."
    
    ssh ${K3S_USER}@${K3S_SERVER} "sudo cat /etc/rancher/k3s/k3s.yaml" > /tmp/k3s-temp.yaml 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Update server address in kubeconfig
        sed "s/127.0.0.1/${K3S_SERVER}/g" /tmp/k3s-temp.yaml > ~/.kube/k3s.yaml
        
        # Backup existing config
        if [ -f ~/.kube/config ]; then
            cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d-%H%M%S)
            print_warning "Backed up existing kubeconfig"
        fi
        
        # Use the new config
        cp ~/.kube/k3s.yaml ~/.kube/config
        chmod 600 ~/.kube/config
        
        print_status "Kubeconfig updated successfully!"
        
        # Test connection
        print_status "Testing cluster connection..."
        if kubectl cluster-info &>/dev/null; then
            print_status "✓ Successfully connected to cluster!"
            echo ""
            kubectl get nodes
        else
            print_error "Could not connect to cluster. Check the kubeconfig."
        fi
        
        # Cleanup
        rm -f /tmp/k3s-temp.yaml
    else
        print_error "Failed to fetch kubeconfig. Do you have sudo access on the server?"
    fi
else
    print_error "Cannot SSH to $K3S_SERVER"
    echo ""
    print_warning "To fix this, you need to:"
    echo "  1. Set up SSH key authentication:"
    echo "     ssh-copy-id ${K3S_USER}@${K3S_SERVER}"
    echo ""
    echo "  2. Or manually copy the kubeconfig:"
    echo "     scp ${K3S_USER}@${K3S_SERVER}:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s.yaml"
    echo "     sed -i 's/127.0.0.1/${K3S_SERVER}/g' ~/.kube/k3s.yaml"
    echo "     cp ~/.kube/k3s.yaml ~/.kube/config"
    echo ""
    echo "  3. Or use Ansible to fetch it:"
    echo "     cd ../ansible"
    echo "     ansible-playbook applications/fetch-kubeconfig.yml"
    echo "     cp ../.artifacts/k3s.yaml ~/.kube/config"
    echo "     sed -i 's/127.0.0.1/${K3S_SERVER}/g' ~/.kube/config"
fi

echo ""
print_status "Setup complete!"

