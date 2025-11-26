# NAS Integration Guide

## 🎯 Overview

This guide shows how to integrate your NAS storage with the Kubernetes media applications for accessing existing media files and downloads.

## 📁 Current Media App Storage

### Current Setup (Fresh Installs)
- **Sonarr**: Fresh install, config in `sonarr-config` PVC
- **Radarr**: Fresh install, config in `radarr-config` PVC  
- **Lidarr**: Fresh install, config in `lidarr-config` PVC

### Volume Mounts
Each app currently has:
- `/config` - Persistent config storage (5Gi PVC)
- `/downloads` - EmptyDir (temporary)
- `/tv`, `/movies`, `/music` - EmptyDir (temporary)

## 🔧 NAS Integration Options

### Option 1: NFS Mounts (Recommended)

If your NAS supports NFS, this is the cleanest approach:

```yaml
# Add to each media app deployment
volumes:
- name: nas-media
  nfs:
    server: YOUR_NAS_IP
    path: /path/to/media
- name: nas-downloads  
  nfs:
    server: YOUR_NAS_IP
    path: /path/to/downloads

# Update volumeMounts
volumeMounts:
- name: nas-media
  mountPath: /media
- name: nas-downloads
  mountPath: /downloads
```

### Option 2: SMB/CIFS Mounts

For SMB shares, you'll need a CSI driver:

```bash
# Install SMB CSI driver
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/deploy/example/smb-provisioner/smb-server-lb.yaml
```

### Option 3: Host Path Mounts

If NAS is mounted on the K8s nodes:

```yaml
volumes:
- name: nas-media
  hostPath:
    path: /mnt/nas/media
    type: Directory
```

## 🚀 Quick NFS Setup

### Step 1: Update Media Apps with NFS

Create this file and apply it:

```bash
# File: k8s/apps/media-with-nas.yaml
cat << 'EOF' > k8s/apps/media-with-nas.yaml
# Sonarr with NFS
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarr
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarr
  template:
    metadata:
      labels:
        app: sonarr
    spec:
      containers:
      - name: sonarr
        image: lscr.io/linuxserver/sonarr:latest
        ports:
        - containerPort: 8989
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 300m
        env:
        - name: PUID
          value: "1000"
        - name: PGID
          value: "1000"
        - name: TZ
          value: "America/Denver"
        volumeMounts:
        - name: config
          mountPath: /config
        - name: nas-downloads
          mountPath: /downloads
        - name: nas-tv
          mountPath: /tv
      volumes:
      - name: config
        persistentVolumeClaim:
          claimName: sonarr-config
      - name: nas-downloads
        nfs:
          server: YOUR_NAS_IP  # Replace with your NAS IP
          path: /path/to/downloads  # Replace with your downloads path
      - name: nas-tv
        nfs:
          server: YOUR_NAS_IP  # Replace with your NAS IP
          path: /path/to/tv  # Replace with your TV shows path
EOF

# Apply the updated deployment
kubectl apply -f k8s/apps/media-with-nas.yaml
```

## 📋 Configuration Steps

### Step 1: Identify Your NAS Setup

What's your NAS configuration?
- **NAS IP**: `192.168.50.X`
- **NFS enabled**: Yes/No
- **Media paths**: 
  - TV Shows: `/path/to/tv`
  - Movies: `/path/to/movies`
  - Music: `/path/to/music`
  - Downloads: `/path/to/downloads`

### Step 2: Test NFS Access

```bash
# Test NFS mount from a K8s node
ssh root@192.168.50.15
showmount -e YOUR_NAS_IP
mount -t nfs YOUR_NAS_IP:/path/to/media /mnt/test
```

### Step 3: Update Deployments

Once you provide your NAS details, I'll update the deployments with proper NFS mounts.

## 🔄 Docker Data Migration

### Current Docker Locations
Find your current Docker data:
```bash
# Check your docker-compose.yml files
grep -r "volumes:" docker/apps/media-apps/
```

### Migration Process
1. **Keep Docker running** for now (no disruption)
2. **Configure NAS access** in K8s apps
3. **Point K8s apps** to same media locations as Docker
4. **Test K8s apps** work with existing media
5. **Migrate configs** when ready
6. **Switch over** when confident

## 📊 Storage Architecture

```
NAS Storage
├── /media/
│   ├── /tv/          → Sonarr (/tv)
│   ├── /movies/      → Radarr (/movies)
│   └── /music/       → Lidarr (/music)
├── /downloads/       → All apps (/downloads)
└── /configs/
    ├── /sonarr/      → Docker configs (to migrate)
    ├── /radarr/      → Docker configs (to migrate)
    └── /lidarr/      → Docker configs (to migrate)
```

## 🎯 Next Steps

1. **Provide NAS details** (IP, paths, NFS/SMB)
2. **I'll update the deployments** with proper mounts
3. **Test media access** in the K8s apps
4. **Migrate configs** when ready
5. **Deploy more apps** (Prowlarr, qBittorrent, etc.)

## 🔧 Troubleshooting

### Permission Issues
```bash
# Fix NFS permissions
kubectl exec -n apps deployment/sonarr -- ls -la /tv
kubectl exec -n apps deployment/sonarr -- chown -R 1000:1000 /downloads
```

### Mount Issues
```bash
# Check NFS mounts in pod
kubectl exec -n apps deployment/sonarr -- mount | grep nfs
kubectl exec -n apps deployment/sonarr -- df -h
```
