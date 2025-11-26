# Networking & DNS Resolution Guide

## Current Network Architecture Issues

### Current Flow (Problematic)
```
Internet → Cloudflare Tunnel → Cloud Gateway → nginx-proxy-manager → Traefik → K8s Service
```

### Problems with Current Setup
1. **Too Many Hops**: Multiple proxy layers add latency and complexity
2. **Header Forwarding Issues**: Real client IP gets lost in translation
3. **SSL/TLS Termination Conflicts**: Multiple layers trying to handle certificates
4. **Complex Debugging**: Hard to trace issues through multiple components
5. **Resource Overhead**: Each proxy layer consumes resources

## Recommended Network Architecture

### Simplified Flow (Recommended)
```
Internet → Cloudflare Tunnel → Traefik → K8s Service
```

### Benefits
- **Reduced Latency**: Fewer hops mean faster response times
- **Simplified SSL**: Single point of SSL termination
- **Better Observability**: Easier to monitor and debug
- **Resource Efficiency**: Less overhead from proxy layers
- **Improved Security**: Fewer attack surfaces

## Implementation Guide

### 1. Update Cloudflare Tunnel Configuration

#### Remove nginx-proxy-manager from tunnel
```yaml
# cloudflared config.yml
tunnel: your-tunnel-id
credentials-file: /path/to/credentials.json

ingress:
  # Direct to Traefik instead of nginx
  - hostname: "*.theblacklodge.dev"
    service: http://192.168.50.15:80  # Traefik HTTP port
    originRequest:
      httpHostHeader: "*.theblacklodge.dev"
      noTLSVerify: true
  - service: http_status:404
```

### 2. Configure Traefik for Cloudflare

#### Update Traefik Configuration
```yaml
# k8s/traefik/traefik-override.yml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |
    # Enable access logs for debugging
    logs:
      general:
        level: INFO
      access:
        enabled: true
        
    # Configure entry points
    ports:
      web:
        port: 80
        redirectTo: websecure
      websecure:
        port: 443
        tls:
          enabled: true
        # Trust Cloudflare IPs for real client IP
        forwardedHeaders:
          trustedIPs:
            - 173.245.48.0/20
            - 103.21.244.0/22
            - 103.22.200.0/22
            - 103.31.4.0/22
            - 141.101.64.0/18
            - 108.162.192.0/18
            - 190.93.240.0/20
            - 188.114.96.0/20
            - 197.234.240.0/22
            - 198.41.128.0/17
            - 162.158.0.0/15
            - 104.16.0.0/13
            - 104.24.0.0/14
            - 172.64.0.0/13
            - 131.0.72.0/22
            - 2400:cb00::/32
            - 2606:4700::/32
            - 2803:f800::/32
            - 2405:b500::/32
            - 2405:8100::/32
            - 2a06:98c0::/29
            - 2c0f:f248::/32

    # Service configuration
    service:
      type: LoadBalancer
      spec:
        externalIPs:
          - 192.168.50.15  # Primary server IP
          - 192.168.50.16  # Secondary server IP (if HA)

    # Additional configuration
    additionalArguments:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.kubernetesingress.ingressendpoint.ip=192.168.50.15"
      - "--entrypoints.websecure.http.tls.options=default@kubernetescrd"
      
    # Enable Prometheus metrics
    metrics:
      prometheus:
        enabled: true
        addEntryPointsLabels: true
        addServicesLabels: true
```

### 3. Fix DNS Resolution Issues

#### Update DNS Records in Cloudflare
```bash
# Ensure these DNS records exist in Cloudflare:
# Type: CNAME, Name: *, Content: your-tunnel-domain.cfargotunnel.com, Proxy: Yes
# Type: CNAME, Name: @, Content: your-tunnel-domain.cfargotunnel.com, Proxy: Yes

# Specific application records (optional, wildcard should handle these):
# grafana.theblacklodge.dev → CNAME → your-tunnel-domain.cfargotunnel.com
# n8n.theblacklodge.dev → CNAME → your-tunnel-domain.cfargotunnel.com
# argo.theblacklodge.dev → CNAME → your-tunnel-domain.cfargotunnel.com
```

#### Test DNS Resolution
```bash
# Test external DNS resolution
dig grafana.theblacklodge.dev
dig n8n.theblacklodge.dev
dig argo.theblacklodge.dev

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup grafana.theblacklodge.dev
```

### 4. Update Application Ingress Configurations

#### Standard Ingress Template
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ app-name }}-ingress
  namespace: {{ app-namespace }}
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
    # Cloudflare specific annotations
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.middlewares: "default-headers@kubernetescrd"
    # Optional: Force HTTPS redirect
    traefik.ingress.kubernetes.io/redirect-entry-point: "websecure"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - {{ app-name }}.theblacklodge.dev
      secretName: {{ app-name }}-tls
  rules:
    - host: {{ app-name }}.theblacklodge.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ app-name }}-service
                port:
                  number: {{ service-port }}
```

#### Create Default Headers Middleware
```yaml
# k8s/traefik/middleware-headers.yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: default-headers
  namespace: default
spec:
  headers:
    frameDeny: true
    sslRedirect: true
    browserXssFilter: true
    contentTypeNosniff: true
    forceSTSHeader: true
    stsIncludeSubdomains: true
    stsPreload: true
    stsSeconds: 31536000
    customRequestHeaders:
      X-Forwarded-Proto: "https"
    customResponseHeaders:
      X-Robots-Tag: "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex"
```

### 5. Certificate Management

#### Update cert-manager ClusterIssuer
```yaml
# k8s/cert-manager/clusterissuer-letsencrypt-dns.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@domain.com
    privateKeySecretRef:
      name: letsencrypt-dns-private-key
    solvers:
    - dns01:
        cloudflare:
          email: your-cloudflare-email@domain.com
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
      selector:
        dnsZones:
        - "theblacklodge.dev"
```

#### Verify Certificate Generation
```bash
# Check certificate status
kubectl get certificates -A

# Check certificate details
kubectl describe certificate grafana-tls -n grafana

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Application Not Accessible Externally
```bash
# Check ingress status
kubectl get ingress -A

# Check Traefik service
kubectl get svc -n kube-system traefik

# Check Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# Test internal connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://grafana.grafana.svc.cluster.local:3000
```

#### 2. SSL Certificate Issues
```bash
# Check certificate status
kubectl get certificates -A

# Check certificate events
kubectl describe certificate grafana-tls -n grafana

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Manual certificate test
openssl s_client -connect grafana.theblacklodge.dev:443 -servername grafana.theblacklodge.dev
```

#### 3. DNS Resolution Problems
```bash
# Test external DNS
dig +short grafana.theblacklodge.dev

# Test from different locations
nslookup grafana.theblacklodge.dev 8.8.8.8
nslookup grafana.theblacklodge.dev 1.1.1.1

# Check Cloudflare DNS settings
curl -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json"
```

#### 4. Real Client IP Issues
```bash
# Check if real IP is being forwarded
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik | grep "X-Forwarded-For"

# Test with curl
curl -H "X-Forwarded-For: 1.2.3.4" https://grafana.theblacklodge.dev
```

## Performance Optimization

### 1. Enable HTTP/2 and HTTP/3
```yaml
# Add to Traefik configuration
additionalArguments:
  - "--entrypoints.websecure.http.tls.options=default@kubernetescrd"
  - "--entrypoints.websecure.http2.maxConcurrentStreams=250"
  - "--experimental.http3=true"
```

### 2. Enable Compression
```yaml
# Create compression middleware
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: compression
  namespace: default
spec:
  compress: {}
```

### 3. Configure Rate Limiting
```yaml
# Create rate limiting middleware
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
  namespace: default
spec:
  rateLimit:
    burst: 100
    average: 50
```

## Monitoring and Observability

### 1. Enable Traefik Metrics
```yaml
# Add to Traefik configuration
metrics:
  prometheus:
    enabled: true
    addEntryPointsLabels: true
    addServicesLabels: true
    addRoutersLabels: true
```

### 2. Set Up Grafana Dashboard
```bash
# Import Traefik dashboard (ID: 4475)
# Configure Prometheus to scrape Traefik metrics
```

### 3. Set Up Alerts
```yaml
# Example alert for high error rate
groups:
- name: traefik
  rules:
  - alert: TraefikHighErrorRate
    expr: rate(traefik_service_requests_total{code=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error rate on Traefik"
      description: "Error rate is {{ $value }} errors per second"
```

This networking guide should resolve your DNS and hostname issues while simplifying your architecture for better performance and maintainability.
