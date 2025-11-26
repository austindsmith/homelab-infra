helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik -f k8s/traefik/values.yaml --wait

# Check IP addressing
kubectl get svc -l app.kubernetes.io/name=traefik

#Check pod health
kubectl get po -l app.kubernetes.io/name=traefik