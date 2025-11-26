#!/bin/bash

echo "🔧 Memory Optimization Script for Resource-Constrained Environment"
echo "================================================================="

export KUBECONFIG=~/.kube/config

echo "📊 Current Memory Usage:"
kubectl top nodes
echo ""

echo "🎯 Memory Optimization Strategies:"
echo "=================================="

echo "1. 🔄 Temporarily stopping resource-heavy apps..."

# Temporarily scale down Dremio (using 979Mi)
echo "- Scaling down Dremio (979Mi memory usage)"
kubectl scale deployment dremio -n datalake --replicas=0

# Temporarily scale down Superset (using 347Mi)
echo "- Scaling down Superset (347Mi memory usage)"
kubectl scale deployment superset -n datalake --replicas=0

echo ""
echo "2. 🔧 Reducing resource limits for running apps..."

# Reduce MLflow memory limit
echo "- Reducing MLflow memory limit"
kubectl patch deployment mlflow -n datalake --patch '{"spec":{"template":{"spec":{"containers":[{"name":"mlflow","resources":{"limits":{"memory":"512Mi","cpu":"250m"},"requests":{"memory":"256Mi","cpu":"100m"}}}]}}}}'

# Reduce Airbyte server memory limit
echo "- Reducing Airbyte server memory limit"
kubectl patch deployment airbyte-server -n datalake --patch '{"spec":{"template":{"spec":{"containers":[{"name":"airbyte-server","resources":{"limits":{"memory":"512Mi","cpu":"250m"},"requests":{"memory":"256Mi","cpu":"100m"}}}]}}}}'

echo ""
echo "3. 🧹 Cleaning up failed pods..."
kubectl delete pods --field-selector=status.phase=Failed -A --ignore-not-found=true

echo ""
echo "4. 📊 Memory usage after optimization:"
sleep 10
kubectl top nodes

echo ""
echo "5. 🎯 Priority App Status:"
echo "========================="

# Check core apps that should keep running
apps=("homepage" "radarr" "sonarr" "lidarr" "prowlarr" "qbittorrent" "grafana" "prometheus")
for app in "${apps[@]}"; do
    status=$(kubectl get pods -A -l app=$app --no-headers 2>/dev/null | awk '{print $4}' | head -1)
    if [ "$status" = "Running" ]; then
        echo "✅ $app: Running"
    else
        echo "⚠️  $app: $status"
    fi
done

echo ""
echo "📋 Recommendations:"
echo "=================="
echo "✅ Freed up ~1.3GB memory by scaling down Dremio + Superset"
echo "✅ Reduced memory limits for MLflow and Airbyte"
echo "🎯 Focus on getting core media apps working first"
echo "💡 Re-enable Dremio/Superset after getting more RAM"
echo ""
echo "🔄 To re-enable scaled-down apps later:"
echo "kubectl scale deployment dremio -n datalake --replicas=1"
echo "kubectl scale deployment superset -n datalake --replicas=1"
