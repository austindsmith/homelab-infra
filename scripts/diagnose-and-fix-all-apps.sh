#!/bin/bash

echo "🔍 Comprehensive Application Diagnosis and Fix Script"
echo "===================================================="

export KUBECONFIG=~/.kube/config

echo "📊 Current Cluster Resource Usage:"
kubectl top nodes
echo ""

echo "🔍 Application Status Check:"
echo "=============================="

# Check all application pods
echo "📋 Pod Status:"
kubectl get pods -A | grep -E "(homepage|radarr|sonarr|lidarr|prowlarr|qbittorrent|overseerr|gitea|vaultwarden|pgadmin|airbyte|dremio|mlflow|nessie|superset|grafana|prometheus|loki)"

echo ""
echo "🌐 Application Connectivity Test:"
echo "=================================="

# Test all applications
apps=(
    "homepage.theblacklodge.dev"
    "radarr.theblacklodge.dev"
    "sonarr.theblacklodge.dev"
    "lidarr.theblacklodge.dev"
    "prowlarr.theblacklodge.dev"
    "qbittorrent.theblacklodge.dev"
    "overseerr.theblacklodge.dev"
    "gitea.theblacklodge.dev"
    "vaultwarden.theblacklodge.dev"
    "pgadmin.theblacklodge.dev"
    "grafana.theblacklodge.dev"
    "prometheus.theblacklodge.dev"
    "superset.theblacklodge.dev"
    "mlflow.theblacklodge.dev"
    "nessie.theblacklodge.dev"
    "airbyte.theblacklodge.dev"
    "dremio.theblacklodge.dev"
    "argocd.theblacklodge.dev"
    "minio-console.theblacklodge.dev"
)

for app in "${apps[@]}"; do
    status=$(curl -H "Host: $app" http://192.168.50.15:30383 -s -o /dev/null -w "%{http_code}")
    if [ "$status" = "200" ] || [ "$status" = "302" ]; then
        echo "✅ $app: $status"
    else
        echo "❌ $app: $status"
    fi
done

echo ""
echo "💾 Storage Structure Analysis:"
echo "=============================="

echo "📁 NFS App Configs Structure:"
kubectl exec -n apps deployment/homepage -- find /app/config -maxdepth 2 -type d 2>/dev/null | head -10

echo ""
echo "📁 Individual App Config Verification:"
for app in radarr sonarr lidarr prowlarr; do
    echo "- $app config:"
    kubectl exec -n apps deployment/$app -- ls -la /config/ 2>/dev/null | head -3 | tail -1 || echo "  Not ready"
done

echo ""
echo "🗄️ Database Connectivity Test:"
echo "=============================="

echo "PostgreSQL Status:"
kubectl get pods -n core -l app=postgresql
kubectl exec -n core deployment/postgresql -- pg_isready -U postgres 2>/dev/null && echo "✅ PostgreSQL is ready" || echo "❌ PostgreSQL not ready"

echo ""
echo "Database Connections:"
for db in airbyte mlflow nessie superset grafana; do
    kubectl exec -n core deployment/postgresql -- psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='$db';" 2>/dev/null | grep -q "1 row" && echo "✅ Database $db exists" || echo "❌ Database $db missing"
done

echo ""
echo "🔧 Automatic Fixes:"
echo "=================="

# Fix common issues
echo "🔄 Restarting failed applications..."

# Restart CrashLoopBackOff pods
kubectl get pods -A | grep CrashLoopBackOff | awk '{print $2 " -n " $1}' | while read pod; do
    echo "Restarting $pod"
    kubectl delete pod $pod 2>/dev/null
done

# Check for pending PVCs
echo "💾 Checking for PVC issues..."
kubectl get pvc -A | grep Pending && echo "⚠️  Found pending PVCs" || echo "✅ All PVCs bound"

echo ""
echo "📈 Final Status Summary:"
echo "======================="

# Count working vs total apps
working=0
total=0
for app in "${apps[@]}"; do
    status=$(curl -H "Host: $app" http://192.168.50.15:30383 -s -o /dev/null -w "%{http_code}")
    total=$((total + 1))
    if [ "$status" = "200" ] || [ "$status" = "302" ]; then
        working=$((working + 1))
    fi
done

echo "📊 Application Success Rate: $working/$total ($(( working * 100 / total ))%)"
echo "💾 PVC Count: $(kubectl get pvc -A | wc -l | xargs echo) total"
echo "🔧 Resource Usage: $(kubectl top nodes | tail -n +2 | awk '{sum+=$5} END {print sum/NR"%"}') average memory"

echo ""
echo "✅ Diagnosis complete! Check output above for issues."
