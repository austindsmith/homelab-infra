# Simple NAS Integration - The Easiest Way

## 🎯 The Simplest Approach: NFS CSI Driver

This is the **easiest and most expandable** way to integrate your NAS with the entire Kubernetes cluster.

## 📋 What You Need

1. **Your NAS IP address** (e.g., `192.168.50.100`)
2. **NFS enabled** on your NAS
3. **One main NFS share** (e.g., `/volume1/kubernetes` or `/mnt/storage`)

## 🚀 One-Time Setup (5 minutes)

### Step 1: Install NFS CSI Driver
```bash
# Install the NFS CSI driver (handles all NFS mounts automatically)
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/example/nfs-provisioner/nfs-server-lb.yaml
```

### Step 2: Create Storage Class
```bash
# Replace YOUR_NAS_IP and YOUR_NFS_PATH with your actual values
cat << 'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: nfs.csi.k8s.io
parameters:
  server: YOUR_NAS_IP          # e.g., 192.168.50.100
  share: YOUR_NFS_PATH         # e.g., /volume1/kubernetes
reclaimPolicy: Retain
volumeBindingMode: Immediate
EOF
```

### Step 3: Test It Works
```bash
# Create a test PVC
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 1Gi
EOF

# Check if it works
kubectl get pvc test-nfs
# Should show "Bound" status

# Clean up test
kubectl delete pvc test-nfs
```

## 📁 Folder Structure on Your NAS

Create these folders on your NAS share:
```
/volume1/kubernetes/          # Main K8s share
├── media/
│   ├── tv/                   # TV shows
│   ├── movies/               # Movies  
│   ├── music/                # Music
│   └── downloads/            # Downloads
├── configs/                  # App configurations
│   ├── sonarr/
│   ├── radarr/
│   └── lidarr/
└── data/                     # Database/app data
    ├── postgres/
    ├── minio/
    └── grafana/
```

## 🎬 Update Media Apps (Automatic)

Once the NFS storage class is set up, just change the PVCs:

```bash
# Update Sonarr to use NFS storage
kubectl patch pvc sonarr-config -n apps --patch '{"spec":{"storageClassName":"nfs-storage"}}'

# Add media volumes
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-tv
  namespace: apps
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-movies
  namespace: apps
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-downloads
  namespace: apps
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 50Gi
EOF
```

## 🔧 Why This Is The Best Approach

### ✅ Advantages:
- **One-time setup** - works for all future apps
- **Automatic mounting** - Kubernetes handles everything
- **Expandable** - just create new PVCs as needed
- **Shared storage** - multiple pods can access same data
- **Persistent** - data survives pod restarts/moves
- **Simple** - no manual NFS mounts on nodes

### 📈 Easy to Expand:
```bash
# Need more storage? Just create a PVC:
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: new-app-data
  namespace: apps
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-storage
  resources:
    requests:
      storage: 10Gi
```

## 🎯 What I Need From You

Just provide:
1. **Your NAS IP**: `192.168.50.???`
2. **Your NFS share path**: `/volume1/???` or `/mnt/???`

Then I'll:
1. ✅ Set up the NFS CSI driver
2. ✅ Create the storage class  
3. ✅ Update all media apps to use NFS
4. ✅ Create shared media volumes
5. ✅ Make it expandable for future apps

## 🚀 Future Apps Will Be Easy

Once this is set up, any new app just needs:
```yaml
volumes:
- name: app-data
  persistentVolumeClaim:
    claimName: my-new-app-pvc
```

**This is the most expandable and maintainable approach!** 🎉
