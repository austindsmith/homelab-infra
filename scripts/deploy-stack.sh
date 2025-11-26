#!/usr/bin/env bash
# deploy-stack.sh - Deploy entire application stack via ArgoCD
# Usage: ./deploy-stack.sh <stack-name>

set -e

STACK=$1

if [ -z "$STACK" ]; then
    echo "Usage: $0 <stack-name>"
    echo "Available stacks: core, monitoring, datalake"
    exit 1
fi

echo "========================================="
echo "  Deploying $STACK Stack"
echo "========================================="
echo ""

# Deploy the stack
STACK_MANIFEST="../k8s/core/argocd/applications/${STACK}-apps.yaml"

if [ ! -f "$STACK_MANIFEST" ]; then
    echo "Error: Stack manifest not found: $STACK_MANIFEST"
    exit 1
fi

echo "Applying stack manifest: $STACK_MANIFEST"
kubectl apply -f "$STACK_MANIFEST"

echo ""
echo "Waiting for applications to sync..."
sleep 10

# List applications in the stack
echo ""
echo "Applications in $STACK stack:"
kubectl get applications -n argocd -l stack=$STACK 2>/dev/null || kubectl get applications -n argocd

echo ""
echo "========================================="
echo "  $STACK Stack Deployment Complete!"
echo "========================================="
echo ""
echo "Monitor progress:"
echo "  kubectl get applications -n argocd"
echo "  https://argo.theblacklodge.dev"

