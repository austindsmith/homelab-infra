#!/bin/bash

# Deploy Media Applications Script
# Deploys Homepage, Sonarr, Radarr, and Lidarr to Kubernetes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

echo "🎬 Media Applications Deployment Script"
echo "======================================="
echo "Deploying: Homepage, Sonarr, Radarr, Lidarr"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please ensure it's installed and configured."
    exit 1
fi

# Check if kubeconfig is set
if [[ -z "${KUBECONFIG}" ]]; then
    export KUBECONFIG=~/.kube/config
    log_info "Using default kubeconfig: ~/.kube/config"
fi

# Create apps namespace
log_info "Creating apps namespace..."
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

# Deploy applications
log_info "Deploying applications..."

# Deploy Homepage
log_info "Deploying Homepage..."
kubectl apply -f "$PROJECT_ROOT/k8s/apps/homepage/deployment.yaml"
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: homepage-config
  namespace: apps
data:
  settings.yaml: |
    title: The Black Lodge
    theme: dark
    color: slate
    headerStyle: clean
    layout:
      Data Lakehouse:
        style: row
        columns: 3
      Media:
        style: row
        columns: 3
      Infrastructure:
        style: row
        columns: 4
  services.yaml: |
    - Data Lakehouse:
        - ArgoCD:
            href: https://argo.theblacklodge.dev
            description: GitOps Deployment
            icon: argocd
        - MinIO Console:
            href: https://minio-console.theblacklodge.dev
            description: Object Storage
            icon: minio
        - Superset:
            href: https://superset.theblacklodge.dev
            description: Data Visualization
            icon: apache-superset
    - Media:
        - Sonarr:
            href: https://sonarr.theblacklodge.dev
            description: TV Series Management
            icon: sonarr
        - Radarr:
            href: https://radarr.theblacklodge.dev
            description: Movie Management
            icon: radarr
        - Lidarr:
            href: https://lidarr.theblacklodge.dev
            description: Music Management
            icon: lidarr
    - Infrastructure:
        - Traefik:
            href: http://192.168.50.15:30383
            description: Ingress Controller
            icon: traefik
        - Kubernetes:
            href: https://k8s.theblacklodge.dev
            description: Cluster Dashboard
            icon: kubernetes
  widgets.yaml: |
    - kubernetes:
        cluster:
          show: true
          cpu: true
          memory: true
          showLabel: true
          label: "cluster"
        nodes:
          show: true
          cpu: true
          memory: true
          showLabel: true
    - resources:
        backend: resources
        expanded: true
        cpu: true
        memory: true
    - search:
        provider: duckduckgo
        target: _blank
EOF

# Deploy Media Apps
log_info "Deploying Sonarr..."
kubectl apply -f "$PROJECT_ROOT/k8s/apps/sonarr/deployment.yaml"

log_info "Deploying Radarr..."
kubectl apply -f "$PROJECT_ROOT/k8s/apps/radarr/deployment.yaml"

log_info "Deploying Lidarr..."
kubectl apply -f "$PROJECT_ROOT/k8s/apps/lidarr/deployment.yaml"

# Wait for deployments
log_info "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/homepage -n apps
kubectl wait --for=condition=available --timeout=300s deployment/sonarr -n apps
kubectl wait --for=condition=available --timeout=300s deployment/radarr -n apps
kubectl wait --for=condition=available --timeout=300s deployment/lidarr -n apps

# Display status
log_success "All applications deployed successfully!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n apps
echo ""
echo "🌐 Access URLs:"
echo "  Homepage: https://homepage.theblacklodge.dev"
echo "  Sonarr:   https://sonarr.theblacklodge.dev"
echo "  Radarr:   https://radarr.theblacklodge.dev"
echo "  Lidarr:   https://lidarr.theblacklodge.dev"
echo ""
echo "📋 Next Steps:"
echo "  1. Configure nginx-proxy-manager with wildcard *.theblacklodge.dev → 192.168.50.15:30383"
echo "  2. Access applications via their URLs above"
echo "  3. Migrate data from Docker if needed (see MEDIA_APPS_MIGRATION_GUIDE.md)"
echo ""
log_success "Deployment complete! 🎉"
