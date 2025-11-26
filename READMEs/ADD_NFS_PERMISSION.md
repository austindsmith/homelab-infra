# Add NFS Permission for K3s Cluster

## The Issue

Your `/volume1/media` NFS export is missing the K3s cluster subnet:

**Current:**
```
/volume1/media  192.168.1.50/24,192.168.1.0/24  ❌ Missing 192.168.50.0/24
```

**Needed:**
```
/volume1/media  192.168.50.0/24,192.168.1.50/24,192.168.1.0/24  ✅
```

## Quick Fix via Synology Web UI

### Step 1: Login to Synology
- Open: http://192.168.1.131:5000
- Login with admin credentials

### Step 2: Navigate to Shared Folders
1. **Control Panel** → **Shared Folder**
2. Find **media** in the list
3. Click **Edit** (or select it and click Edit button)

### Step 3: Add NFS Permission
1. Click the **NFS Permissions** tab
2. Click **Create** button
3. Fill in the form:
   ```
   Server or IP address: 192.168.50.0/24
   Privilege: Read/Write
   Squash: No mapping
   Security: sys
   ☑ Enable asynchronous
   ☑ Allow connections from non-privileged ports
   ☑ Allow users to access mounted subfolders
   ```
4. Click **OK**
5. Click **OK** again to save the shared folder settings

### Step 4: Verify
Open terminal and run:
```bash
showmount -e 192.168.1.131 | grep media
```

Should now show:
```
/volume1/media  192.168.50.0/24,192.168.1.50/24,192.168.1.0/24
```

## Alternative: SSH Method

If you prefer SSH:

```bash
# SSH to NAS
ssh admin@192.168.1.131

# Switch to root
sudo -i

# Edit exports file
nano /etc/exports

# Find the line with /volume1/media
# Add: 192.168.50.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# Save and exit (Ctrl+X, Y, Enter)

# Reload exports
exportfs -ra

# Verify
showmount -e localhost | grep media
```

## After Adding the Permission

Once you've added the NFS permission, let me know and I'll:
1. Restart the NFS CSI controller
2. Delete and recreate the media-storage PVC
3. Watch the pods start automatically

Or you can run:
```bash
cd /mnt/secondary_ssd/Code/homelab/infra/scripts
./test-and-fix-nfs.sh
```

This will automatically fix everything once NFS permissions are correct!

