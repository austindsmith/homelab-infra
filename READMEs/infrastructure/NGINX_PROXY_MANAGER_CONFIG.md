# nginx-proxy-manager Configuration - CORRECTED

## 🔧 The Issue
You were pointing nginx-proxy-manager directly to the applications, but it should point to **Traefik** which then routes to the applications based on hostnames.

## ✅ Correct Configuration

### Single Proxy Host for All Applications
Create **ONE** proxy host in nginx-proxy-manager:

**Domain Names**: `*.theblacklodge.dev` (wildcard)
**Forward Hostname/IP**: `192.168.50.15`
**Forward Port**: `30383` (Traefik HTTP port)
**Scheme**: `http`

### Advanced Tab Settings:
```
# Forward the original host header to Traefik
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

## 🌐 How It Works

```
Internet → Cloudflare Tunnel → nginx-proxy-manager → Traefik → Applications
                                (*.theblacklodge.dev)    (routes by hostname)
```

1. **nginx-proxy-manager** receives requests for `*.theblacklodge.dev`
2. **nginx-proxy-manager** forwards ALL requests to Traefik (192.168.50.15:30383)
3. **Traefik** looks at the `Host` header and routes to the correct application:
   - `argo.theblacklodge.dev` → ArgoCD service
   - `minio-console.theblacklodge.dev` → MinIO console
   - `superset.theblacklodge.dev` → Superset service

## 🧪 Testing

After configuring nginx-proxy-manager:

1. **Test Traefik directly**:
   ```bash
   curl -H "Host: argo.theblacklodge.dev" http://192.168.50.15:30383
   ```

2. **Test through nginx-proxy-manager**:
   ```bash
   curl https://argo.theblacklodge.dev
   ```

## 🔍 Troubleshooting

If still getting bad gateway:

1. **Check Traefik logs**:
   ```bash
   kubectl logs -n traefik deployment/traefik
   ```

2. **Check Ingress status**:
   ```bash
   kubectl describe ingress argocd-ingress -n argocd
   ```

3. **Test individual services**:
   ```bash
   kubectl get svc -A
   ```

## 📋 Current Ingress Routes

| Hostname | Service | Port | Status |
|----------|---------|------|--------|
| argo.theblacklodge.dev | argocd-server | 80 | ✅ Created |
| minio-console.theblacklodge.dev | minio | 9001 | ✅ Created |
| minio.theblacklodge.dev | minio | 9000 | ✅ Created |
| superset.theblacklodge.dev | superset | 8088 | ✅ Created |

All routes are configured to go through Traefik on port 30383.
