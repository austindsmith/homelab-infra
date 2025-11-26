#!/bin/bash

# Script to extract all credentials from the deployed K8s cluster
# This ensures reproducibility and provides access to all service credentials

set -e

echo "🔐 Extracting Data Lakehouse Credentials..."
echo "=========================================="

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ kubectl is not configured or cluster is not accessible"
    exit 1
fi

CREDS_FILE="$(dirname "$0")/../CREDENTIALS_EXTRACTED.md"

cat > "$CREDS_FILE" << 'EOF'
# Extracted Data Lakehouse Credentials

**Generated on:** $(date)
**Cluster:** $(kubectl config current-context)

## Core Infrastructure

EOF

echo "📋 Extracting ArgoCD credentials..."
if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    cat >> "$CREDS_FILE" << EOF

### ArgoCD
- **URL**: https://argo.theblacklodge.dev
- **Username**: admin
- **Password**: \`$ARGOCD_PASSWORD\`

EOF
else
    echo "⚠️  ArgoCD secret not found"
fi

echo "📋 Extracting MinIO credentials..."
if kubectl get secret minio -n datalake &>/dev/null; then
    MINIO_ACCESS_KEY=$(kubectl -n datalake get secret minio -o jsonpath="{.data.rootUser}" | base64 -d)
    MINIO_SECRET_KEY=$(kubectl -n datalake get secret minio -o jsonpath="{.data.rootPassword}" | base64 -d)
    cat >> "$CREDS_FILE" << EOF

### MinIO Object Storage
- **Console URL**: https://minio-console.theblacklodge.dev
- **API URL**: https://minio.theblacklodge.dev
- **Access Key**: \`$MINIO_ACCESS_KEY\`
- **Secret Key**: \`$MINIO_SECRET_KEY\`

EOF
else
    echo "⚠️  MinIO secret not found, checking Helm values..."
    if [ -f "$(dirname "$0")/../k8s/datalake/minio/values.yaml" ]; then
        MINIO_ACCESS_KEY=$(grep -A1 "rootUser:" "$(dirname "$0")/../k8s/datalake/minio/values.yaml" | tail -1 | sed 's/.*: //' | tr -d '"')
        MINIO_SECRET_KEY=$(grep -A1 "rootPassword:" "$(dirname "$0")/../k8s/datalake/minio/values.yaml" | tail -1 | sed 's/.*: //' | tr -d '"')
        cat >> "$CREDS_FILE" << EOF

### MinIO Object Storage
- **Console URL**: https://minio-console.theblacklodge.dev
- **API URL**: https://minio.theblacklodge.dev
- **Access Key**: \`$MINIO_ACCESS_KEY\`
- **Secret Key**: \`$MINIO_SECRET_KEY\`

EOF
    fi
fi

cat >> "$CREDS_FILE" << 'EOF'

## Data Lakehouse Applications

### Dremio Query Engine
- **URL**: https://dremio.theblacklodge.dev
- **Setup**: Complete first-time setup wizard
- **Note**: Create admin user during initial setup

### Nessie Data Versioning
- **URL**: https://nessie.theblacklodge.dev
- **Type**: API service (no web UI login required)
- **Database**: PostgreSQL backend

EOF

echo "📋 Extracting PostgreSQL credentials..."
if kubectl get secret nessie-postgresql -n datalake &>/dev/null; then
    PG_PASSWORD=$(kubectl -n datalake get secret nessie-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
    cat >> "$CREDS_FILE" << EOF

### PostgreSQL (Nessie Backend)
- **Host**: nessie-postgresql.datalake.svc.cluster.local
- **Database**: nessie
- **Username**: postgres
- **Password**: \`$PG_PASSWORD\`

EOF
else
    echo "⚠️  PostgreSQL secret not found"
fi

cat >> "$CREDS_FILE" << 'EOF'

## Service Status

EOF

echo "📋 Checking service status..."
kubectl get pods -n argocd -o wide >> "$CREDS_FILE" 2>/dev/null || echo "ArgoCD pods not found" >> "$CREDS_FILE"
echo "" >> "$CREDS_FILE"
kubectl get pods -n datalake -o wide >> "$CREDS_FILE" 2>/dev/null || echo "Datalake pods not found" >> "$CREDS_FILE"
echo "" >> "$CREDS_FILE"

cat >> "$CREDS_FILE" << 'EOF'

## Ingress Routes

EOF

kubectl get ingress -A >> "$CREDS_FILE" 2>/dev/null || echo "No ingress routes found" >> "$CREDS_FILE"

echo "✅ Credentials extracted to: $CREDS_FILE"
echo ""
echo "🌐 Access URLs:"
echo "   ArgoCD: https://argo.theblacklodge.dev"
echo "   MinIO Console: https://minio-console.theblacklodge.dev"
echo "   Dremio: https://dremio.theblacklodge.dev"
echo "   Nessie API: https://nessie.theblacklodge.dev"
echo ""
echo "📝 Next Steps:"
echo "   1. Add these domains to nginx-proxy-manager"
echo "   2. Point them to: 192.168.50.15:80"
echo "   3. Test access in browser"
