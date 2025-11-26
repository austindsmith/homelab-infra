#!/bin/bash

# Script to test connectivity through the nginx → Traefik → K8s chain

echo "🔍 Testing K8s Services Connectivity..."
echo "========================================="

# Test Traefik directly
echo "1. Testing Traefik LoadBalancer (192.168.50.15:80)..."
curl -s -H "Host: argo.theblacklodge.dev" http://192.168.50.15:80 -I | head -1

# Test ArgoCD service internally
echo -e "\n2. Testing ArgoCD service internally..."
kubectl get pods -n argocd | grep argocd-server

# Test MinIO service internally  
echo -e "\n3. Testing MinIO service internally..."
kubectl get pods -n datalake | grep minio

# Show ingress status
echo -e "\n4. Ingress Routes Status..."
kubectl get ingress -A

# Show service endpoints
echo -e "\n5. Service Endpoints..."
echo "ArgoCD: https://argo.theblacklodge.dev"
echo "MinIO API: https://minio.theblacklodge.dev" 
echo "MinIO Console: https://minio-console.theblacklodge.dev"

echo -e "\n6. ArgoCD Admin Credentials..."
echo "Username: admin"
if [ -f ~/.argocd-password ]; then
    echo "Password: $(cat ~/.argocd-password)"
else
    echo "Password: Run 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d'"
fi

echo -e "\n7. MinIO Credentials..."
echo "Username: [See k8s/global-secrets.yaml or CREDENTIALS.md]"
echo "Password: [See k8s/global-secrets.yaml or CREDENTIALS.md]"

echo -e "\n✅ Next Steps:"
echo "1. Configure nginx-proxy-manager proxy hosts (see instructions above)"
echo "2. Ensure Cloudflare tunnel points *.theblacklodge.dev to your Docker host"
echo "3. Create Cloudflare API secret: ./scripts/create-cloudflare-secret.sh YOUR_TOKEN"
echo "4. Test access: https://argo.theblacklodge.dev"
