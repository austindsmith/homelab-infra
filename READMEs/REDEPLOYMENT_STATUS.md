# Redeployment Status - November 24, 2025

## Summary

Redeployment has been initiated after NAS storage was wiped. Most core infrastructure is running, but there are NFS connectivity issues preventing some applications from starting.

## ✅ Successfully Running

### Core Services
- **PostgreSQL** - Running on local-path storage (working around NFS permission issues)
- **ArgoCD** - Fully operational
- **Cert-Manager** - Fully operational  
- **Traefik** - Fully operational
- **MetalLB** - Fully operational

### Applications
- **Gitea** - Running (using NFS storage successfully)
- **Prowlarr** - Running (using NFS storage successfully)

### Infrastructure
- **NFS CSI Driver** - Running
- **Local Path Provisioner** - Running
- **CoreDNS** - Running
- **Metrics Server** - Running

## ⚠️ Pending/Issues

### Apps Waiting for NFS Storage
The following apps are pending because the `media-storage` PVC cannot be provisioned:
- **Radarr** - Pending (waiting for media-storage PVC)
- **Sonarr** - Pending (waiting for media-storage PVC)
- **Lidarr** - Pending (waiting for media-storage PVC)
- **qBittorrent** - Pending (waiting for media-storage PVC)

### Apps with Other Issues
- **Overseerr** - ContainerCreating
- **pgAdmin** - ContainerCreating
- **Grafana** - ContainerCreating
- **Vaultwarden** - Error/CrashLoop
- **n8n** - ImagePullBackOff
- **MLflow** - ImagePullBackOff
- **Nessie** - ContainerCreating
- **Superset** - Init container running

## 🔍 Root Cause: NFS Connectivity Issue

The NFS CSI provisioner is timing out when trying to create volumes on the NAS at `192.168.1.131:/volume1/media`:

```
Warning  ProvisioningFailed    failed to provision volume with StorageClass "nfs-media": 
rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

### Possible Causes:
1. **NFS exports not configured** on the NAS
2. **Network connectivity** issues between cluster and NAS
3. **NFS permissions** not allowing the provisioner to create subdirectories
4. **Firewall** blocking NFS traffic

## 🔧 Immediate Actions Needed

### 1. Fix NFS Connectivity

Check NFS exports on the NAS (192.168.1.131):
```bash
# On the NAS
showmount -e localhost

# Should show:
# /volume1/infrastructure/kubernetes *
# /volume1/media *
```

Verify network connectivity from cluster:
```bash
# From any cluster node
showmount -e 192.168.1.131
```

### 2. Alternative: Use Local Storage for Media Apps

If NFS cannot be fixed quickly, media apps can use local-path storage temporarily:
- Change `storageClassName` from `nfs-media` to `local-path` in media app deployments
- Note: This means media files won't be on the NAS

### 3. Fix Image Pull Issues

Some apps have `ImagePullBackOff`:
- **n8n**: Check if image `n8nio/n8n:1.15.0` exists
- **MLflow**: Check if image `ghcr.io/mlflow/mlflow:v2.8.0` exists

## 📊 Current Cluster State

### Namespaces
- `core` - PostgreSQL running
- `apps` - 2/10 apps running
- `datalake` - 0/3 apps running  
- `monitoring` - 0/1 apps running
- `argocd` - Fully operational
- `cert-manager` - Fully operational
- `traefik` - Fully operational

### Storage
- **local-path** - Working (PostgreSQL, Gitea, Prowlarr using it)
- **nfs-infrastructure** - Working for some apps
- **nfs-media** - NOT working (provisioning timeout)

## 🎯 Next Steps

### Option A: Fix NFS (Recommended)
1. SSH to NAS: `ssh admin@192.168.1.131`
2. Check NFS exports: Control Panel → File Services → NFS
3. Ensure `/volume1/media` is exported with:
   - Squash: No mapping
   - Security: sys
   - Enable asynchronous: Yes
   - Allow connections from non-privileged ports: Yes
4. Test from cluster node: `showmount -e 192.168.1.131`
5. Delete and recreate media-storage PVC

### Option B: Use Local Storage Temporarily
1. Delete pending deployments
2. Update deployments to use `local-path` instead of `nfs-media`
3. Redeploy apps
4. Move to NFS later when fixed

### Option C: Rebuild with Proper NFS Setup
If NFS issues persist, consider:
1. Backing up working apps (Gitea, Prowlarr configs)
2. Fixing NFS exports properly
3. Redeploying everything fresh

## 📝 Commands to Check Status

```bash
# Check all pods
kubectl get pods --all-namespaces

# Check PVCs
kubectl get pvc --all-namespaces

# Check specific app
kubectl describe pod -n apps <pod-name>
kubectl logs -n apps <pod-name>

# Check NFS provisioner logs
kubectl logs -n kube-system -l app=csi-nfs-controller

# Test NFS from node
ssh root@192.168.50.15 "showmount -e 192.168.1.131"
```

## 💾 What's on the NAS Now

Since you deleted `/volume1/infrastructure/kubernetes/`, apps that successfully started have created new folders:
- `/volume1/infrastructure/kubernetes/gitea/` - Fresh Gitea data
- `/volume1/infrastructure/kubernetes/prowlarr/` - Fresh Prowlarr config

PostgreSQL is on local storage at `/var/lib/rancher/k3s/storage/` on the control plane node.

## ⏰ Time to Resolution

- **If NFS can be fixed**: 10-15 minutes to get all apps running
- **If using local storage**: 5 minutes to get apps running (but no NAS backup)
- **If rebuilding**: 30-60 minutes for complete rebuild

---

**Current Status**: Partial deployment complete. Core infrastructure healthy. Waiting on NFS connectivity fix to complete media app deployment.

