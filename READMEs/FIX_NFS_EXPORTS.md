# Fix NFS Exports on Synology NAS

## The Problem

Your NFS exports are configured to only allow access from `192.168.1.0/24`, but your K3s cluster is on `192.168.50.0/24`. 

Current exports:
```
/volume1/infrastructure 192.168.50.0/24,192.168.1.0/24  ✅ Correct
/volume1/media          192.168.1.50/24,192.168.1.0/24  ❌ Missing 192.168.50.0/24
```

## How to Fix via Synology Web UI

### Step 1: Access Synology DSM
1. Open browser to: http://192.168.1.131:5000 (or https://192.168.1.131:5001)
2. Login with your admin credentials

### Step 2: Open NFS Settings
1. Go to **Control Panel**
2. Click **File Services**
3. Click the **NFS** tab
4. Make sure "Enable NFS service" is checked

### Step 3: Edit NFS Rules for /volume1/media
1. Go to **Control Panel** → **Shared Folder**
2. Find **media** folder
3. Click **Edit**
4. Go to **NFS Permissions** tab
5. You should see existing rules for `192.168.1.0/24`

### Step 4: Add K3s Cluster Access
Click **Create** and add a new rule:
- **Server or IP address**: `192.168.50.0/24`
- **Privilege**: Read/Write
- **Squash**: No mapping
- **Security**: sys
- **Enable asynchronous**: ✅ Checked
- **Allow connections from non-privileged ports**: ✅ Checked
- **Allow users to access mounted subfolders**: ✅ Checked

Click **OK** to save.

### Step 5: Do the Same for /volume1/infrastructure/kubernetes
1. Go to **Shared Folder** → **infrastructure**
2. Click **Edit** → **NFS Permissions**
3. Verify `192.168.50.0/24` is in the list (it should be based on the exports)
4. If not, add it with the same settings as above

## Alternative: Fix via SSH (Faster)

If you have SSH access to the NAS:

```bash
# SSH to NAS
ssh admin@192.168.1.131

# Become root
sudo -i

# Edit NFS exports
vi /etc/exports

# Find the line for /volume1/media and add 192.168.50.0/24
# Change from:
# /volume1/media 192.168.1.50/24(...) 192.168.1.0/24(...)
# To:
# /volume1/media 192.168.1.50/24(...) 192.168.1.0/24(...) 192.168.50.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# Reload NFS exports
exportfs -ra

# Verify
showmount -e localhost
```

## Verify the Fix

From your local machine or any cluster node:

```bash
# Check exports
showmount -e 192.168.1.131

# Should now show:
# /volume1/media 192.168.50.0/24,192.168.1.50/24,192.168.1.0/24
```

## After Fixing NFS

Once NFS is fixed, redeploy the media storage:

```bash
# Delete the stuck PVC
ssh root@192.168.50.15 "kubectl delete pvc media-storage -n apps"

# Recreate it
ssh root@192.168.50.15 "kubectl apply -f /tmp/k8s/storage/media-storage.yaml"

# Wait a moment, then check
ssh root@192.168.50.15 "kubectl get pvc -n apps media-storage"
# Should show "Bound" status

# The pending pods should automatically start
ssh root@192.168.50.15 "kubectl get pods -n apps"
```

## Quick Test

Test NFS mount from a cluster node:

```bash
# SSH to a cluster node
ssh root@192.168.50.15

# Try to mount manually
mkdir -p /mnt/test-nfs
mount -t nfs 192.168.1.131:/volume1/media /mnt/test-nfs

# If successful, check contents
ls -la /mnt/test-nfs

# Unmount
umount /mnt/test-nfs
```

## Common Issues

### Issue: "Permission denied" when mounting
**Solution**: Make sure "Allow connections from non-privileged ports" is enabled

### Issue: "Access denied by server"
**Solution**: Check that the IP range includes your cluster subnet (192.168.50.0/24)

### Issue: "No route to host"
**Solution**: Check firewall rules on the NAS allow NFS (port 2049)

### Issue: Still timing out after fixing
**Solution**: 
1. Restart NFS service on NAS: `sudo systemctl restart nfs-server`
2. Or reboot the NAS
3. Restart the NFS CSI controller in K8s:
   ```bash
   kubectl rollout restart deployment csi-nfs-controller -n kube-system
   ```

## NFS Ports to Check

Make sure these ports are open on the NAS firewall:
- **TCP/UDP 111** - RPC portmapper
- **TCP/UDP 2049** - NFS
- **TCP/UDP 20048** - mountd

## Expected Final Configuration

After the fix, your exports should look like:

```
/volume1/infrastructure 192.168.50.0/24,192.168.1.0/24
/volume1/media          192.168.50.0/24,192.168.1.50/24,192.168.1.0/24
```

Both accessible from the K3s cluster at 192.168.50.x!

