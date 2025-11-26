# Media Apps Migration Guide

## 🎯 Overview

This guide helps migrate Sonarr and Radarr configuration data from Docker to Kubernetes deployments.

## 📋 Current Deployment Status

### ✅ Deployed Applications
- **Homepage**: https://homepage.theblacklodge.dev
- **Sonarr**: https://sonarr.theblacklodge.dev  
- **Radarr**: https://radarr.theblacklodge.dev
- **Lidarr**: https://lidarr.theblacklodge.dev (fresh install)

### 💾 Persistent Storage
Each app has a 5GB PersistentVolumeClaim for configuration:
- `sonarr-config` → `/config` in pod
- `radarr-config` → `/config` in pod  
- `lidarr-config` → `/config` in pod

## 🔄 Data Migration Process

### Step 1: Locate Docker Data

Find your Docker volumes/bind mounts:
```bash
# Check your docker-compose.yml files
ls -la /path/to/docker/volumes/sonarr/
ls -la /path/to/docker/volumes/radarr/
```

### Step 2: Copy Data to Kubernetes

#### Option A: Direct Copy (if accessible)
```bash
# Get the pod names
export KUBECONFIG=~/.kube/config
kubectl get pods -n apps

# Copy Sonarr config
kubectl cp /path/to/docker/sonarr/config/ apps/sonarr-pod-name:/config/

# Copy Radarr config  
kubectl cp /path/to/docker/radarr/config/ apps/radarr-pod-name:/config/
```

#### Option B: Via Temporary Pod
```bash
# Create a temporary pod with access to the PVC
kubectl run -n apps temp-sonarr --image=busybox --rm -it --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"temp","image":"busybox","command":["sleep","3600"],"volumeMounts":[{"name":"config","mountPath":"/config"}]}],"volumes":[{"name":"config","persistentVolumeClaim":{"claimName":"sonarr-config"}}]}}'

# In another terminal, copy files
kubectl cp /path/to/docker/sonarr/config/ apps/temp-sonarr:/config/

# Clean up
kubectl delete pod temp-sonarr -n apps
```

### Step 3: Restart Applications
```bash
# Restart to pick up migrated config
kubectl rollout restart deployment sonarr -n apps
kubectl rollout restart deployment radarr -n apps
```

### Step 4: Verify Migration
1. Access the web UIs via the hostnames above
2. Check that your shows/movies are still configured
3. Verify download clients and indexers are working

## 🔧 Troubleshooting

### Permission Issues
If you get permission errors:
```bash
# Fix ownership in the pod
kubectl exec -n apps deployment/sonarr -- chown -R 1000:1000 /config
kubectl exec -n apps deployment/radarr -- chown -R 1000:1000 /config
```

### Database Issues
If the apps won't start after migration:
```bash
# Check logs
kubectl logs -n apps deployment/sonarr
kubectl logs -n apps deployment/radarr

# Reset if needed (will lose config)
kubectl delete pvc sonarr-config -n apps
kubectl delete pvc radarr-config -n apps
```

## 📁 File Locations

### In Docker
- Config: Usually `/config` or bind mount location
- Database: `config/sonarr.db` or `config/radarr.db`
- Settings: `config/config.xml`

### In Kubernetes
- Config: `/config` (mounted from PVC)
- Same file structure as Docker

## 🚀 Deployment Commands (Reproducible)

To redeploy these applications:

```bash
# Deploy all apps
kubectl apply -f k8s/apps/homepage/deployment.yaml
kubectl apply -f k8s/apps/sonarr/deployment.yaml  
kubectl apply -f k8s/apps/radarr/deployment.yaml
kubectl apply -f k8s/apps/lidarr/deployment.yaml

# Apply Homepage config
kubectl apply -f k8s/apps/homepage/configmap.yaml
```

## 🌐 Access URLs

All applications are accessible via:
- **Homepage**: https://homepage.theblacklodge.dev
- **Sonarr**: https://sonarr.theblacklodge.dev
- **Radarr**: https://radarr.theblacklodge.dev  
- **Lidarr**: https://lidarr.theblacklodge.dev

## 📊 Resource Usage

Each media app uses:
- **Memory**: 256Mi request, 512Mi limit
- **CPU**: 100m request, 300m limit
- **Storage**: 5Gi persistent volume for config

## 🔄 Backup Strategy

To backup configurations:
```bash
# Backup Sonarr config
kubectl exec -n apps deployment/sonarr -- tar czf - /config > sonarr-backup.tar.gz

# Backup Radarr config  
kubectl exec -n apps deployment/radarr -- tar czf - /config > radarr-backup.tar.gz
```

## 📝 Next Steps

1. **Test the applications** via their web UIs
2. **Migrate data** from Docker if needed
3. **Configure download clients** to point to new locations
4. **Update Homepage** links and widgets as needed
5. **Set up monitoring** and health checks
