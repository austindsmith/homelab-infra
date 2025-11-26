#!/usr/bin/env bash
# deploy-app.sh - Deploy individual application via ArgoCD
# Usage: ./deploy-app.sh <app-name>

set -e

APP_NAME=$1

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name>"
    echo "Example: $0 minio"
    exit 1
fi

echo "Deploying application: $APP_NAME"

# Find the application manifest
APP_MANIFEST=$(find ../k8s -name "*${APP_NAME}*.yaml" -path "*/applications/*" | head -n 1)

if [ -z "$APP_MANIFEST" ]; then
    echo "Error: Application manifest not found for $APP_NAME"
    exit 1
fi

echo "Found manifest: $APP_MANIFEST"
kubectl apply -f "$APP_MANIFEST"

echo "Waiting for application to sync..."
sleep 5

# Check application status
kubectl get application "$APP_NAME" -n argocd

echo ""
echo "Application $APP_NAME deployed!"
echo "Check status: kubectl get application $APP_NAME -n argocd"
echo "View in ArgoCD UI: https://argo.theblacklodge.dev"

