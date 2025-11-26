#!/bin/bash

# Credential Management Script
# Helps create and manage Kubernetes secrets securely

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

# Generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Create global secrets file
create_secrets_file() {
    local secrets_file="$PROJECT_ROOT/k8s/global-secrets.yaml"
    
    if [[ -f "$secrets_file" ]]; then
        log_warning "Secrets file already exists: $secrets_file"
        read -p "Overwrite existing file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing secrets file."
            return 0
        fi
    fi
    
    log_info "Generating new credentials..."
    
    # Generate passwords
    MINIO_PASSWORD=$(generate_password)
    SUPERSET_PASSWORD=$(generate_password)
    POSTGRES_SUPERSET_PASSWORD=$(generate_password)
    POSTGRES_AIRBYTE_PASSWORD=$(generate_password)
    POSTGRES_MLFLOW_PASSWORD=$(generate_password)
    POSTGRES_NESSIE_PASSWORD=$(generate_password)
    
    cat > "$secrets_file" << EOF
# Global Secrets - DO NOT COMMIT TO GIT
# Generated on: $(date)

apiVersion: v1
kind: Secret
metadata:
  name: global-credentials
  namespace: default
type: Opaque
stringData:
  # MinIO Credentials
  minio-root-user: "admin"
  minio-root-password: "$MINIO_PASSWORD"
  
  # Database Passwords
  postgres-superset-password: "$POSTGRES_SUPERSET_PASSWORD"
  postgres-airbyte-password: "$POSTGRES_AIRBYTE_PASSWORD"
  postgres-mlflow-password: "$POSTGRES_MLFLOW_PASSWORD"
  postgres-nessie-password: "$POSTGRES_NESSIE_PASSWORD"
  
  # Application Admin Passwords
  superset-admin-password: "$SUPERSET_PASSWORD"
  
  # Cloudflare API Token (SET THIS MANUALLY)
  cloudflare-api-token: "CHANGE_ME_TO_YOUR_CLOUDFLARE_TOKEN"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: global-config
  namespace: default
data:
  # Timezone
  TZ: "America/Denver"
  
  # User/Group IDs
  PUID: "1000"
  PGID: "1000"
  
  # Database usernames (non-sensitive)
  postgres-superset-user: "superset"
  postgres-airbyte-user: "airbyte"
  postgres-mlflow-user: "mlflow"
  postgres-nessie-user: "postgres"
EOF

    log_success "Created secrets file: $secrets_file"
    log_warning "Remember to:"
    log_warning "1. Set your Cloudflare API token in the file"
    log_warning "2. Apply the secrets: kubectl apply -f k8s/global-secrets.yaml"
    log_warning "3. NEVER commit this file to git (it's in .gitignore)"
    
    echo ""
    echo "📋 Generated Credentials:"
    echo "MinIO Password: $MINIO_PASSWORD"
    echo "Superset Password: $SUPERSET_PASSWORD"
    echo ""
}

# Apply secrets to cluster
apply_secrets() {
    local secrets_file="$PROJECT_ROOT/k8s/global-secrets.yaml"
    
    if [[ ! -f "$secrets_file" ]]; then
        log_error "Secrets file not found: $secrets_file"
        log_info "Run: $0 create"
        exit 1
    fi
    
    log_info "Applying secrets to Kubernetes cluster..."
    kubectl apply -f "$secrets_file"
    log_success "Secrets applied successfully!"
}

# Show current secrets (masked)
show_secrets() {
    log_info "Current secrets in cluster:"
    kubectl get secret global-credentials -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null || {
        log_warning "No global-credentials secret found in cluster"
        log_info "Run: $0 apply"
    }
}

# Clean up credentials from files that shouldn't have them
cleanup_credentials() {
    log_info "Cleaning up hardcoded credentials from files..."
    
    # Remove credentials from test scripts
    if [[ -f "$PROJECT_ROOT/scripts/test-connectivity.sh" ]]; then
        sed -i 's/Password: [a-zA-Z0-9]*/Password: [REDACTED]/g' "$PROJECT_ROOT/scripts/test-connectivity.sh"
        sed -i 's/Username: [a-zA-Z0-9]*/Username: [REDACTED]/g' "$PROJECT_ROOT/scripts/test-connectivity.sh"
    fi
    
    log_success "Credential cleanup completed"
}

# Main function
main() {
    case "${1:-help}" in
        "create")
            create_secrets_file
            ;;
        "apply")
            apply_secrets
            ;;
        "show")
            show_secrets
            ;;
        "cleanup")
            cleanup_credentials
            ;;
        "help"|*)
            echo "Credential Management Script"
            echo ""
            echo "Usage: $0 {create|apply|show|cleanup|help}"
            echo ""
            echo "Commands:"
            echo "  create   - Generate new global-secrets.yaml file"
            echo "  apply    - Apply secrets to Kubernetes cluster"
            echo "  show     - Show current secrets in cluster (masked)"
            echo "  cleanup  - Remove hardcoded credentials from files"
            echo "  help     - Show this help message"
            echo ""
            echo "Workflow:"
            echo "  1. $0 create     # Generate secrets file"
            echo "  2. Edit k8s/global-secrets.yaml to set Cloudflare token"
            echo "  3. $0 apply      # Apply to cluster"
            echo "  4. $0 cleanup    # Clean up any remaining hardcoded creds"
            ;;
    esac
}

main "$@"
