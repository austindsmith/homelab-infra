#!/bin/bash

echo "🧹 Kubernetes Cleanup and Optimization Script"
echo "=============================================="

export KUBECONFIG=~/.kube/config

echo "📊 Current Resource Usage:"
kubectl top nodes
echo ""

echo "🗑️  Cleaning up unused resources..."

# Clean up failed/succeeded pods
echo "- Removing failed/succeeded pods..."
kubectl delete pods --field-selector=status.phase=Failed -A --ignore-not-found=true
kubectl delete pods --field-selector=status.phase=Succeeded -A --ignore-not-found=true

# Clean up evicted pods
echo "- Removing evicted pods..."
kubectl get pods -A | grep Evicted | awk '{print $2 " -n " $1}' | xargs -r kubectl delete pod

# Clean up old ReplicaSets
echo "- Removing old ReplicaSets..."
kubectl delete rs -A --field-selector=status.replicas=0 --ignore-not-found=true

# Clean up unused PVCs (after confirming apps are using shared storage)
echo "- Checking for unused individual PVCs..."
kubectl get pvc -A

echo ""
echo "🔧 Optimizing configurations..."

# Update Airbyte to use centralized PostgreSQL
echo "- Updating Airbyte to use centralized PostgreSQL..."
kubectl patch deployment airbyte-server -n datalake --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "airbyte-server",
          "env": [
            {"name": "DATABASE_HOST", "value": "postgresql.core.svc.cluster.local"},
            {"name": "DATABASE_PORT", "value": "5432"},
            {"name": "DATABASE_PASSWORD", "value": "airbyte123"},
            {"name": "DATABASE_USER", "value": "airbyte"},
            {"name": "DATABASE_DB", "value": "airbyte"}
          ]
        }]
      }
    }
  }
}' 2>/dev/null || echo "  Airbyte not ready yet"

# Update MLflow to use centralized PostgreSQL
echo "- Updating MLflow to use centralized PostgreSQL..."
kubectl patch deployment mlflow -n datalake --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "mlflow",
          "command": ["/bin/bash"],
          "args": ["-c", "pip install mlflow psycopg2-binary boto3 && mlflow server --backend-store-uri postgresql://mlflow:mlflow123@postgresql.core.svc.cluster.local:5432/mlflow --default-artifact-root s3://mlflow-artifacts/ --host 0.0.0.0 --port 5000"]
        }]
      }
    }
  }
}' 2>/dev/null || echo "  MLflow not ready yet"

# Update Nessie to use centralized PostgreSQL  
echo "- Updating Nessie to use centralized PostgreSQL..."
kubectl patch deployment nessie -n datalake --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "nessie",
          "env": [
            {"name": "QUARKUS_DATASOURCE_JDBC_URL", "value": "jdbc:postgresql://postgresql.core.svc.cluster.local:5432/nessie"},
            {"name": "QUARKUS_DATASOURCE_USERNAME", "value": "nessie"},
            {"name": "QUARKUS_DATASOURCE_PASSWORD", "value": "nessie123"}
          ]
        }]
      }
    }
  }
}' 2>/dev/null || echo "  Nessie not ready yet"

echo ""
echo "📈 Current pod status:"
kubectl get pods -A | grep -v Running | grep -v Completed

echo ""
echo "💾 Storage usage:"
kubectl get pvc -A

echo ""
echo "🎯 Resource usage after cleanup:"
kubectl top nodes

echo ""
echo "✅ Cleanup and optimization complete!"
echo "📝 Check logs if any applications need manual intervention."
