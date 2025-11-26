#!/bin/bash

# Check Health of All Kubernetes Applications
# This script checks the status and health of all deployed applications

set -e

echo "=== Kubernetes Application Health Check ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check pod status
check_pod_status() {
    local namespace=$1
    local app=$2
    
    echo -n "  Checking $app... "
    
    # Get pod status
    pod_status=$(kubectl get pods -n $namespace -l app=$app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$pod_status" == "Running" ]; then
        # Check if containers are ready
        ready=$(kubectl get pods -n $namespace -l app=$app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        if [ "$ready" == "true" ]; then
            echo -e "${GREEN}✓ Running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Running but not ready${NC}"
            return 1
        fi
    elif [ "$pod_status" == "Pending" ]; then
        echo -e "${YELLOW}⚠ Pending${NC}"
        return 1
    elif [ "$pod_status" == "NotFound" ]; then
        echo -e "${RED}✗ Not Found${NC}"
        return 1
    else
        echo -e "${RED}✗ $pod_status${NC}"
        return 1
    fi
}

# Function to get pod logs
get_pod_logs() {
    local namespace=$1
    local app=$2
    
    echo ""
    echo "Recent logs for $app:"
    kubectl logs -n $namespace -l app=$app --tail=10 2>/dev/null || echo "  No logs available"
    echo ""
}

echo "Core Services (namespace: core):"
check_pod_status "core" "postgresql" || get_pod_logs "core" "postgresql"

echo ""
echo "Media Applications (namespace: apps):"
check_pod_status "apps" "radarr" || get_pod_logs "apps" "radarr"
check_pod_status "apps" "sonarr" || get_pod_logs "apps" "sonarr"
check_pod_status "apps" "lidarr" || get_pod_logs "apps" "lidarr"
check_pod_status "apps" "prowlarr" || get_pod_logs "apps" "prowlarr"
check_pod_status "apps" "qbittorrent" || get_pod_logs "apps" "qbittorrent"
check_pod_status "apps" "overseerr" || get_pod_logs "apps" "overseerr"

echo ""
echo "Datalake Applications (namespace: datalake):"
check_pod_status "datalake" "airbyte" || get_pod_logs "datalake" "airbyte"
check_pod_status "datalake" "dremio" || get_pod_logs "datalake" "dremio"
check_pod_status "datalake" "mlflow" || get_pod_logs "datalake" "mlflow"
check_pod_status "datalake" "spark-master" || get_pod_logs "datalake" "spark-master"
check_pod_status "datalake" "superset" || get_pod_logs "datalake" "superset"
check_pod_status "datalake" "nessie" || get_pod_logs "datalake" "nessie"

echo ""
echo "Monitoring Applications (namespace: monitoring):"
check_pod_status "monitoring" "grafana" || get_pod_logs "monitoring" "grafana"

echo ""
echo "Other Applications (namespace: apps):"
check_pod_status "apps" "gitea" || get_pod_logs "apps" "gitea"
check_pod_status "apps" "vaultwarden" || get_pod_logs "apps" "vaultwarden"
check_pod_status "apps" "pgadmin" || get_pod_logs "apps" "pgadmin"
check_pod_status "apps" "n8n" || get_pod_logs "apps" "n8n"

echo ""
echo "=== Storage Status ==="
echo ""
echo "PersistentVolumeClaims:"
kubectl get pvc --all-namespaces

echo ""
echo "=== Service Status ==="
echo ""
kubectl get svc --all-namespaces | grep -E "core|apps|datalake|monitoring"

echo ""
echo "=== Ingress Status ==="
echo ""
kubectl get ingress --all-namespaces

echo ""
echo "=== Health Check Complete ==="

