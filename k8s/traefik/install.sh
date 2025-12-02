helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik --namespace traefik --create-namespace -f k8s/traefik/values.yaml --wait 

# Check IP addressing
kubectl get svc -l app.kubernetes.io/name=traefik

# Check pod health
kubectl get po -l app.kubernetes.io/name=traefik

# Add a manual DNS entry in /etc/hosts (or C:\Windows\System32\Drivers\etc\hosts if you're a Windows person)
# for 192.168.50.61 (or whatever your traefik IP is) and go to http://dashboard.local/ and you should see a sweet dashboard screen