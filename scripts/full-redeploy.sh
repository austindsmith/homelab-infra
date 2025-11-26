#!/bin/bash

# Full Redeployment Script
# Use this after deleting NAS storage to recreate everything

set -e

echo "=== Full Kubernetes Application Redeployment ==="
echo ""
echo "This will:"
echo "  1. Delete all existing deployments and PVCs"
echo "  2. Recreate storage and applications"
echo "  3. Allow apps to initialize fresh data directories"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check kubectl access
if ! kubectl cluster-info &>/dev/null; then
    print_error "Cannot connect to cluster. Please run setup-kubectl-access.sh first or manually configure kubectl."
    exit 1
fi

print_status "Connected to cluster successfully!"
echo ""

# Confirm deletion
read -p "This will delete and recreate all applications. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
print_status "Step 1: Deleting existing deployments..."

# Delete all deployments in apps namespace
kubectl delete deployment --all -n apps --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment --all -n datalake --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment --all -n monitoring --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment --all -n core --ignore-not-found=true 2>/dev/null || true

print_status "Waiting for pods to terminate..."
sleep 10

echo ""
print_status "Step 2: Deleting existing PVCs..."

# Delete all PVCs
kubectl delete pvc --all -n apps --ignore-not-found=true 2>/dev/null || true
kubectl delete pvc --all -n datalake --ignore-not-found=true 2>/dev/null || true
kubectl delete pvc --all -n monitoring --ignore-not-found=true 2>/dev/null || true
kubectl delete pvc --all -n core --ignore-not-found=true 2>/dev/null || true

print_status "Waiting for PVCs to be deleted..."
sleep 10

echo ""
print_status "Step 3: Recreating storage classes..."
kubectl apply -f ../k8s/storage/nfs-storage-classes.yaml
kubectl apply -f ../k8s/storage/media-storage.yaml
sleep 5

echo ""
print_status "Step 4: Deploying PostgreSQL..."
kubectl apply -f ../k8s/core/postgresql/init-databases.yaml
kubectl apply -f ../k8s/core/postgresql/deployment.yaml

print_warning "Waiting for PostgreSQL to initialize (this may take 2-3 minutes)..."
kubectl wait --for=condition=ready pod -l app=postgresql -n core --timeout=300s || {
    print_warning "PostgreSQL taking longer than expected. Checking status..."
    kubectl get pods -n core
    kubectl logs -n core -l app=postgresql --tail=20
}

# Give PostgreSQL extra time to fully initialize databases
sleep 30

echo ""
print_status "Step 5: Deploying Media Applications..."

print_status "  - Deploying Radarr..."
kubectl apply -f ../k8s/apps/radarr/deployment.yaml
sleep 2

print_status "  - Deploying Sonarr..."
kubectl apply -f ../k8s/apps/sonarr/deployment.yaml
sleep 2

print_status "  - Deploying Lidarr..."
kubectl apply -f ../k8s/apps/lidarr/deployment.yaml
sleep 2

print_status "  - Deploying Prowlarr..."
kubectl apply -f ../k8s/apps/prowlarr/deployment.yaml
sleep 2

print_status "  - Deploying qBittorrent..."
kubectl apply -f ../k8s/apps/qbittorrent/deployment.yaml
sleep 2

print_status "  - Deploying Overseerr..."
kubectl apply -f ../k8s/apps/overseerr/deployment.yaml
sleep 2

echo ""
print_status "Step 6: Deploying Datalake Applications..."

print_status "  - Deploying Airbyte..."
kubectl apply -f ../k8s/datalake/airbyte/deployment.yaml
sleep 2

print_status "  - Deploying Dremio..."
kubectl apply -f ../k8s/datalake/dremio/deployment.yaml
sleep 2

print_status "  - Deploying MLflow..."
kubectl apply -f ../k8s/datalake/mlflow/deployment.yaml
sleep 2

print_status "  - Deploying Spark..."
kubectl apply -f ../k8s/datalake/spark/deployment.yaml
sleep 2

print_status "  - Deploying Superset..."
kubectl apply -f ../k8s/datalake/superset/deployment.yaml
sleep 2

print_status "  - Deploying Nessie..."
kubectl apply -f ../k8s/datalake/nessie/deployment.yaml
sleep 2

echo ""
print_status "Step 7: Deploying Monitoring Applications..."

print_status "  - Deploying Grafana..."
kubectl apply -f ../k8s/monitoring/grafana/deployment.yaml
sleep 2

echo ""
print_status "Step 8: Deploying Other Applications..."

print_status "  - Deploying Gitea..."
kubectl apply -f ../k8s/apps/gitea/deployment.yaml
sleep 2

print_status "  - Deploying Vaultwarden..."
kubectl apply -f ../k8s/apps/vaultwarden/deployment.yaml
sleep 2

print_status "  - Deploying pgAdmin..."
kubectl apply -f ../k8s/apps/pgadmin/deployment.yaml
sleep 2

print_status "  - Deploying n8n..."
kubectl apply -f ../k8s/apps/n8n/deployment.yaml
sleep 2

echo ""
print_status "Step 9: Waiting for applications to initialize..."
print_warning "This may take 5-10 minutes as apps create their initial configurations..."
sleep 30

echo ""
print_status "=== Deployment Status ==="
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

echo "PersistentVolumeClaims:"
kubectl get pvc --all-namespaces
echo ""

print_status "=== Redeployment Complete ==="
echo ""
print_warning "Notes:"
echo "  - Applications are initializing and creating their data directories"
echo "  - Some apps may take 5-10 minutes to fully start"
echo "  - Check status with: kubectl get pods --all-namespaces"
echo "  - Check health with: ./check-app-health.sh"
echo "  - View logs with: kubectl logs <pod-name> -n <namespace>"
echo ""
print_status "Your applications will create fresh configurations on the NAS at:"
echo "  /volume1/infrastructure/kubernetes/<app-name>/"
echo ""

