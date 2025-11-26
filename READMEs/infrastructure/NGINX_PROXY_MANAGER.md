# nginx-proxy-manager Configuration Guide

## Overview
Configure nginx-proxy-manager to route all services from your Kubernetes cluster through Cloudflare tunnels.

## Target Configuration
**All domains point to**: `192.168.50.15:80` (Traefik LoadBalancer)

## Proxy Host Configurations

### 1. Homepage (Main Dashboard)
- **Domain Names**: `homepage.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`
- **Cache Assets**: OFF
- **Block Common Exploits**: ON
- **Websockets Support**: ON

### 2. ArgoCD (GitOps Platform)
- **Domain Names**: `argo.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`
- **Cache Assets**: OFF
- **Block Common Exploits**: ON
- **Websockets Support**: ON

### 3. Data Lakehouse Services

#### MinIO Console
- **Domain Names**: `minio-console.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### MinIO API
- **Domain Names**: `minio.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Dremio Query Engine
- **Domain Names**: `dremio.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Nessie Data Versioning
- **Domain Names**: `nessie.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Apache Superset
- **Domain Names**: `superset.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Apache Spark
- **Domain Names**: `spark.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### MLflow
- **Domain Names**: `mlflow.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Airbyte
- **Domain Names**: `airbyte.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

### 4. Media Management Services

#### Sonarr
- **Domain Names**: `sonarr.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Radarr
- **Domain Names**: `radarr.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

#### Lidarr
- **Domain Names**: `lidarr.theblacklodge.dev`
- **Scheme**: `http`
- **Forward Hostname/IP**: `192.168.50.15`
- **Forward Port**: `80`

## SSL Configuration
- **Force SSL**: ON (for all services)
- **HTTP/2 Support**: ON
- **HSTS Enabled**: ON
- **HSTS Subdomains**: ON

## Advanced Settings (Optional)
For each proxy host, you can add these custom nginx configurations:

### Custom Nginx Configuration
```nginx
# Increase proxy timeouts for data processing services
proxy_connect_timeout       300;
proxy_send_timeout          300;
proxy_read_timeout          300;
send_timeout                300;

# Increase buffer sizes for large responses
proxy_buffer_size           4k;
proxy_buffers               4 32k;
proxy_busy_buffers_size     64k;

# Enable compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

## Cloudflare Tunnel Configuration
Ensure your Cloudflare tunnel is configured to route:
- **Public hostname**: `*.theblacklodge.dev`
- **Service**: `http://[YOUR_DOCKER_HOST_IP]:80`

## Testing
After configuration, test each service:
1. **Start with Homepage**: https://homepage.theblacklodge.dev
2. **Verify all links work** from the Homepage dashboard
3. **Check SSL certificates** are automatically issued

## Troubleshooting
- **502 Bad Gateway**: Check if `192.168.50.15:80` is accessible from your Docker host
- **SSL Issues**: Verify cert-manager is running and Cloudflare API token is configured
- **Timeout Issues**: Add the custom nginx configuration above

## Quick Setup Script
Run this on your nginx-proxy-manager host to verify connectivity:
```bash
# Test connectivity to Traefik
curl -H "Host: homepage.theblacklodge.dev" http://192.168.50.15:80 -I

# Should return HTTP 200 or redirect
```
