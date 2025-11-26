#!/bin/bash

# Cleanup Old/Unused Kubernetes Resources
# This script removes old PVCs and deployments that are no longer needed

set -e

echo "=== Cleaning Up Old Kubernetes Resources ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# List of old PVCs to potentially remove (shared PVCs that were replaced with individual ones)
OLD_PVCS=(
    "app-configs:apps"
    "database-storage:apps"
    "temp-media-storage:apps"
    "monitoring-storage:monitoring"
)

# List of old deployments/resources to check
OLD_DEPLOYMENTS=(
    "radarr-old:apps"
    "sonarr-old:apps"
)

echo ""
print_status "Step 1: Checking for unused PVCs..."
echo ""

for pvc_info in "${OLD_PVCS[@]}"; do
    IFS=':' read -r pvc namespace <<< "$pvc_info"
    
    if kubectl get pvc "$pvc" -n "$namespace" &> /dev/null; then
        print_warning "Found old PVC: $pvc in namespace $namespace"
        
        # Check if any pods are using this PVC
        pods_using=$(kubectl get pods -n "$namespace" -o json | jq -r ".items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == \"$pvc\") | .metadata.name" 2>/dev/null || echo "")
        
        if [ -z "$pods_using" ]; then
            print_status "  No pods using this PVC. Safe to delete."
            echo "  To delete, run: kubectl delete pvc $pvc -n $namespace"
        else
            print_warning "  Still in use by: $pods_using"
        fi
    fi
done

echo ""
print_status "Step 2: Checking for failed/completed pods..."
echo ""

# Find and list failed pods
failed_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed -o json | jq -r '.items[] | "\(.metadata.name):\(.metadata.namespace)"' 2>/dev/null || echo "")

if [ -n "$failed_pods" ]; then
    print_warning "Found failed pods:"
    echo "$failed_pods"
    echo ""
    echo "To delete all failed pods, run:"
    echo "kubectl delete pods --all-namespaces --field-selector=status.phase=Failed"
else
    print_status "No failed pods found."
fi

echo ""
print_status "Step 3: Checking for pods in ImagePullBackOff or CrashLoopBackOff..."
echo ""

problem_pods=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason | select(. == "ImagePullBackOff" or . == "CrashLoopBackOff")) | "\(.metadata.name):\(.metadata.namespace):\(.status.containerStatuses[0].state.waiting.reason)"' 2>/dev/null || echo "")

if [ -n "$problem_pods" ]; then
    print_warning "Found pods with issues:"
    echo "$problem_pods"
    echo ""
    print_warning "Review these pods and fix the underlying issues."
else
    print_status "No pods with ImagePullBackOff or CrashLoopBackOff found."
fi

echo ""
print_status "Step 4: Checking for unused ConfigMaps and Secrets..."
echo ""

# This is informational only - be careful deleting ConfigMaps/Secrets
print_warning "ConfigMaps in apps namespace:"
kubectl get configmaps -n apps

echo ""
print_warning "Secrets in apps namespace (excluding default):"
kubectl get secrets -n apps | grep -v default-token

echo ""
print_status "Step 5: Disk usage on NAS (if accessible)..."
echo ""
print_warning "Check NAS storage at /volume1/infrastructure/kubernetes for:"
print_warning "  - Old application folders that are no longer used"
print_warning "  - Large log files"
print_warning "  - Temporary files"

echo ""
print_status "=== Cleanup Summary ==="
echo ""
echo "Manual cleanup commands (review before running):"
echo ""
echo "# Delete old shared PVCs (ONLY if no longer in use):"
echo "# kubectl delete pvc app-configs -n apps"
echo "# kubectl delete pvc database-storage -n apps"
echo "# kubectl delete pvc temp-media-storage -n apps"
echo ""
echo "# Delete failed pods:"
echo "# kubectl delete pods --all-namespaces --field-selector=status.phase=Failed"
echo ""
echo "# Delete completed jobs (if any):"
echo "# kubectl delete jobs --all-namespaces --field-selector=status.successful=1"
echo ""

print_status "=== Cleanup Check Complete ==="
print_warning "Review the output above and run cleanup commands manually as needed."

