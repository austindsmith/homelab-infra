#!/bin/bash
# Check status of both K3s and Talos clusters

set -e

echo "=========================================="
echo "Homelab Cluster Status Check"
echo "=========================================="
echo ""

# Check if we can reach Proxmox
echo "Checking Proxmox connectivity..."
if ping -c 1 -W 2 proxmox.theblacklodge.org &> /dev/null; then
    echo "✅ Proxmox is reachable"
else
    echo "❌ Cannot reach Proxmox"
    exit 1
fi

echo ""
echo "=========================================="
echo "K3s Cluster (Existing)"
echo "=========================================="

K3S_IPS=("192.168.50.15" "192.168.50.16" "192.168.50.17")
K3S_NAMES=("lab-k8s-01" "lab-k8s-02" "lab-k8s-03")

for i in "${!K3S_IPS[@]}"; do
    IP="${K3S_IPS[$i]}"
    NAME="${K3S_NAMES[$i]}"
    
    if ping -c 1 -W 2 "$IP" &> /dev/null; then
        echo "✅ $NAME ($IP) - ONLINE"
    else
        echo "❌ $NAME ($IP) - OFFLINE"
    fi
done

echo ""
echo "=========================================="
echo "Talos Trial Cluster (New)"
echo "=========================================="

TALOS_IPS=("192.168.50.25" "192.168.50.26" "192.168.50.27")
TALOS_NAMES=("talos-trial-01" "talos-trial-02" "talos-trial-03")

for i in "${!TALOS_IPS[@]}"; do
    IP="${TALOS_IPS[$i]}"
    NAME="${TALOS_NAMES[$i]}"
    
    if ping -c 1 -W 2 "$IP" &> /dev/null; then
        echo "✅ $NAME ($IP) - ONLINE"
    else
        echo "⚠️  $NAME ($IP) - OFFLINE (may not be deployed yet)"
    fi
done

echo ""
echo "=========================================="
echo "Resource Summary"
echo "=========================================="
echo ""
echo "K3s Cluster:"
echo "  - VMs: 3"
echo "  - RAM: 24GB total (8GB each)"
echo "  - CPU: 12 cores total (4 each)"
echo "  - Disk: 300GB total (100GB each)"
echo ""
echo "Talos Trial Cluster:"
echo "  - VMs: 3"
echo "  - RAM: 6GB total (2GB each)"
echo "  - CPU: 6 cores total (2 each)"
echo "  - Disk: 60GB total (20GB each)"
echo ""
echo "Combined Total:"
echo "  - VMs: 6"
echo "  - RAM: 30GB"
echo "  - CPU: 18 cores"
echo "  - Disk: 360GB"
echo ""

