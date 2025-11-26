#!/bin/bash

# Deploy Fixed Kubernetes Applications
# This script deploys all applications with proper NAS storage configuration

set -e

echo "=== Deploying Fixed Kubernetes Applications ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Create namespaces if they don't exist
print_status "Creating namespaces..."
kubectl create namespace core --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace datalake --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo ""
print_status "Step 1: Deploying Storage Classes and PVCs"
kubectl apply -f ../k8s/storage/nfs-storage-classes.yaml
kubectl apply -f ../k8s/storage/media-storage.yaml
sleep 5

echo ""
print_status "Step 2: Deploying Core Services (PostgreSQL)"
kubectl apply -f ../k8s/core/postgresql/init-databases.yaml
kubectl apply -f ../k8s/core/postgresql/deployment.yaml
print_warning "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgresql -n core --timeout=300s || print_warning "PostgreSQL may not be ready yet"
sleep 10

echo ""
print_status "Step 3: Deploying Media Applications"
print_status "  - Deploying Radarr..."
kubectl apply -f ../k8s/apps/radarr/deployment.yaml

print_status "  - Deploying Sonarr..."
kubectl apply -f ../k8s/apps/sonarr/deployment.yaml

print_status "  - Deploying Lidarr..."
kubectl apply -f ../k8s/apps/lidarr/deployment.yaml

print_status "  - Deploying Prowlarr..."
kubectl apply -f ../k8s/apps/prowlarr/deployment.yaml

print_status "  - Deploying qBittorrent..."
kubectl apply -f ../k8s/apps/qbittorrent/deployment.yaml

print_status "  - Deploying Overseerr..."
kubectl apply -f ../k8s/apps/overseerr/deployment.yaml

echo ""
print_status "Step 4: Deploying Datalake Applications"
print_status "  - Deploying Airbyte..."
kubectl apply -f ../k8s/datalake/airbyte/deployment.yaml

print_status "  - Deploying Dremio..."
kubectl apply -f ../k8s/datalake/dremio/deployment.yaml

print_status "  - Deploying MLflow..."
kubectl apply -f ../k8s/datalake/mlflow/deployment.yaml

print_status "  - Deploying Spark..."
kubectl apply -f ../k8s/datalake/spark/deployment.yaml

print_status "  - Deploying Superset..."
kubectl apply -f ../k8s/datalake/superset/deployment.yaml

print_status "  - Deploying Nessie..."
kubectl apply -f ../k8s/datalake/nessie/deployment.yaml

echo ""
print_status "Step 5: Deploying Monitoring Applications"
print_status "  - Deploying Grafana..."
kubectl apply -f ../k8s/monitoring/grafana/deployment.yaml

echo ""
print_status "Step 6: Deploying Other Applications"
print_status "  - Deploying Gitea..."
kubectl apply -f ../k8s/apps/gitea/deployment.yaml

print_status "  - Deploying Vaultwarden..."
kubectl apply -f ../k8s/apps/vaultwarden/deployment.yaml

print_status "  - Deploying pgAdmin..."
kubectl apply -f ../k8s/apps/pgadmin/deployment.yaml

print_status "  - Deploying n8n..."
kubectl apply -f ../k8s/apps/n8n/deployment.yaml

echo ""
print_status "Step 7: Waiting for deployments to be ready..."
sleep 10

echo ""
print_status "=== Deployment Summary ==="
echo ""
echo "Core Services:"
kubectl get pods -n core
echo ""
echo "Applications:"
kubectl get pods -n apps
echo ""
echo "Datalake:"
kubectl get pods -n datalake
echo ""
echo "Monitoring:"
kubectl get pods -n monitoring
echo ""

print_status "=== Deployment Complete ==="
print_warning "Note: Some applications may take a few minutes to fully start."
print_warning "Run 'kubectl get pods --all-namespaces' to check the status of all pods."
print_warning "Run './check-app-health.sh' to verify application health."

