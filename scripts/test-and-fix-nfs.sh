#!/bin/bash

# Test and Fix NFS Storage Issues
# Run this after updating NFS exports on the NAS

set -e

echo "=== Testing and Fixing NFS Storage ==="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

NAS_IP="192.168.1.131"
K3S_SERVER="192.168.50.15"

echo "Step 1: Check NFS exports from NAS"
echo "-----------------------------------"
if showmount -e $NAS_IP 2>/dev/null | grep -q "192.168.50"; then
    print_status "NFS exports include 192.168.50.0/24 subnet"
    showmount -e $NAS_IP | grep volume1
else
    print_error "NFS exports do NOT include 192.168.50.0/24 subnet"
    echo ""
    echo "Current exports:"
    showmount -e $NAS_IP
    echo ""
    print_warning "Please fix NFS exports on the NAS first!"
    print_warning "See FIX_NFS_EXPORTS.md for instructions"
    exit 1
fi

echo ""
echo "Step 2: Test NFS mount from cluster node"
echo "-----------------------------------------"
if ssh root@$K3S_SERVER "mkdir -p /mnt/test-nfs && mount -t nfs $NAS_IP:/volume1/media /mnt/test-nfs && ls /mnt/test-nfs > /dev/null 2>&1 && umount /mnt/test-nfs"; then
    print_status "NFS mount test successful!"
else
    print_error "NFS mount test failed"
    print_warning "Check NFS service on NAS and firewall rules"
    exit 1
fi

echo ""
echo "Step 3: Restart NFS CSI controller"
echo "-----------------------------------"
ssh root@$K3S_SERVER "kubectl rollout restart deployment csi-nfs-controller -n kube-system"
print_status "NFS CSI controller restarted"
sleep 10

echo ""
echo "Step 4: Delete and recreate media-storage PVC"
echo "----------------------------------------------"
ssh root@$K3S_SERVER "kubectl delete pvc media-storage -n apps --ignore-not-found=true"
print_status "Deleted old media-storage PVC"
sleep 5

ssh root@$K3S_SERVER "kubectl apply -f /tmp/k8s/storage/media-storage.yaml"
print_status "Created new media-storage PVC"

echo ""
echo "Step 5: Wait for PVC to bind"
echo "----------------------------"
for i in {1..30}; do
    STATUS=$(ssh root@$K3S_SERVER "kubectl get pvc media-storage -n apps -o jsonpath='{.status.phase}' 2>/dev/null" || echo "NotFound")
    if [ "$STATUS" == "Bound" ]; then
        print_status "PVC is now Bound!"
        break
    elif [ "$STATUS" == "Pending" ]; then
        echo -n "."
        sleep 2
    else
        print_warning "PVC status: $STATUS"
        sleep 2
    fi
done

echo ""
echo ""
echo "Step 6: Check PVC status"
echo "------------------------"
ssh root@$K3S_SERVER "kubectl get pvc -n apps media-storage"

PVC_STATUS=$(ssh root@$K3S_SERVER "kubectl get pvc media-storage -n apps -o jsonpath='{.status.phase}' 2>/dev/null" || echo "NotFound")
if [ "$PVC_STATUS" == "Bound" ]; then
    print_status "Media storage PVC is ready!"
    echo ""
    echo "Step 7: Check pod status"
    echo "------------------------"
    ssh root@$K3S_SERVER "kubectl get pods -n apps | grep -E 'radarr|sonarr|lidarr|qbittorrent'"
    echo ""
    print_status "Pods should start automatically now!"
    print_status "Wait 1-2 minutes and check: kubectl get pods -n apps"
else
    print_error "PVC is still not bound: $PVC_STATUS"
    echo ""
    echo "Check PVC events:"
    ssh root@$K3S_SERVER "kubectl describe pvc media-storage -n apps | tail -20"
fi

echo ""
echo "=== NFS Fix Complete ==="

