#!/bin/bash

# Complete Data Lakehouse Stack Deployment
# This script automates the entire deployment process from fresh K3s cluster to working data lakehouse
# Ensures 100% reproducibility without manual kubectl commands

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Data Lakehouse Complete Stack Deployment"
echo "============================================"
echo "Project Root: $PROJECT_ROOT"
echo "Timestamp: $(date)"
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not configured or cluster is not accessible"
        log_info "Make sure KUBECONFIG is set: export KUBECONFIG=~/.kube/config"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Deploy core infrastructure
deploy_core_infrastructure() {
    log_info "Deploying core infrastructure..."
    
    # Deploy Traefik (should already be deployed via Ansible)
    if ! kubectl get deployment traefik -n traefik &>/dev/null; then
        log_warning "Traefik not found, deploying..."
        helm install traefik "$PROJECT_ROOT/k8s/core/traefik" -n traefik --create-namespace
    else
        log_success "Traefik already deployed"
    fi
    
    # Deploy cert-manager (should already be deployed via Ansible)
    if ! kubectl get deployment cert-manager -n cert-manager &>/dev/null; then
        log_warning "cert-manager not found, deploying..."
        helm install cert-manager "$PROJECT_ROOT/k8s/core/cert-manager" -n cert-manager --create-namespace
    else
        log_success "cert-manager already deployed"
    fi
    
    # Deploy ArgoCD (should already be deployed via Ansible)
    if ! kubectl get deployment argocd-server -n argocd &>/dev/null; then
        log_warning "ArgoCD not found, deploying..."
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for ArgoCD to be ready
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
        
        # Configure ArgoCD for insecure mode
        kubectl patch configmap argocd-cm -n argocd --type merge -p='{"data":{"url":"https://argo.theblacklodge.dev","server.insecure":"true"}}'
        kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p='{"data":{"server.insecure":"true"}}'
        
        # Create ArgoCD ingress
        kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - argo.theblacklodge.dev
    secretName: argocd-server-tls
  rules:
  - host: argo.theblacklodge.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF
        
        # Restart ArgoCD server to apply configuration
        kubectl rollout restart deployment argocd-server -n argocd
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
        
    else
        log_success "ArgoCD already deployed"
    fi
}

# Deploy data lakehouse applications
deploy_datalake_apps() {
    log_info "Deploying data lakehouse applications..."
    
    # Create datalake namespace
    kubectl create namespace datalake --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy MinIO
    log_info "Deploying MinIO object storage..."
    if ! helm list -n datalake | grep -q minio; then
        helm install minio "$PROJECT_ROOT/k8s/datalake/minio" -n datalake
    else
        helm upgrade minio "$PROJECT_ROOT/k8s/datalake/minio" -n datalake
    fi
    
    # Deploy Dremio
    log_info "Deploying Dremio query engine..."
    if ! helm list -n datalake | grep -q dremio; then
        helm install dremio "$PROJECT_ROOT/k8s/datalake/dremio" -n datalake
    else
        helm upgrade dremio "$PROJECT_ROOT/k8s/datalake/dremio" -n datalake
    fi
    
    # Deploy Nessie
    log_info "Deploying Nessie data versioning..."
    if ! helm list -n datalake | grep -q nessie; then
        helm install nessie "$PROJECT_ROOT/k8s/datalake/nessie" -n datalake
    else
        helm upgrade nessie "$PROJECT_ROOT/k8s/datalake/nessie" -n datalake
    fi
    
    # Wait for deployments to be ready
    log_info "Waiting for data lakehouse applications to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=minio -n datalake --timeout=300s || log_warning "MinIO not ready yet"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=dremio -n datalake --timeout=300s || log_warning "Dremio not ready yet"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=nessie -n datalake --timeout=300s || log_warning "Nessie not ready yet"
}

# Extract and display credentials
extract_credentials() {
    log_info "Extracting credentials..."
    "$SCRIPT_DIR/extract-credentials.sh"
}

# Display deployment summary
show_summary() {
    log_success "Deployment completed successfully!"
    echo ""
    echo "🌐 Access URLs (add these to nginx-proxy-manager):"
    echo "   ArgoCD: https://argo.theblacklodge.dev"
    echo "   MinIO Console: https://minio-console.theblacklodge.dev"
    echo "   Dremio: https://dremio.theblacklodge.dev"
    echo "   Nessie API: https://nessie.theblacklodge.dev"
    echo ""
    echo "🔧 nginx-proxy-manager configuration:"
    echo "   - Create proxy hosts for each domain above"
    echo "   - Point all to: 192.168.50.15:80"
    echo "   - Enable SSL and websockets support"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Configure nginx-proxy-manager proxy hosts"
    echo "   2. Create Cloudflare API secret: ./scripts/create-cloudflare-secret.sh YOUR_TOKEN"
    echo "   3. Test access to all services"
    echo "   4. Complete Dremio first-time setup"
    echo ""
    echo "📊 Cluster status:"
    kubectl get pods -A | grep -E "(argocd|datalake|traefik|cert-manager)"
}

# Main execution
main() {
    check_prerequisites
    deploy_core_infrastructure
    deploy_datalake_apps
    extract_credentials
    show_summary
}

# Run main function
main "$@"
