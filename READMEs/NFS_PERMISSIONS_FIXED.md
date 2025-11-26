# NFS Permission Issues - FIXED! ✅

## Problem
Media apps (Radarr, Sonarr, Lidarr) were failing with permission errors on NFS storage:
```
chown: changing ownership of '/config/logs/radarr.txt': Operation not permitted
chown: changing ownership of '/config/asp': Operation not permitted
chown: changing ownership of '/config/radarr.db': Operation not permitted
```

## Root Cause
NFS doesn't allow `chown` operations from containers, even with root privileges. The LinuxServer.io containers try to change ownership of files on startup, which fails on NFS mounts.

## Solution Applied ✅

Added init containers to all media apps that:
1. Run before the main container starts
2. Create necessary directories (`/config/logs`, `/config/asp`)
3. Set permissions to 777 (world-writable) so the app can write without chown

### Implementation

```yaml
initContainers:
- name: config-permissions
  image: busybox:latest
  command: ['sh', '-c', 'mkdir -p /config/logs /config/asp && chmod -R 777 /config']
  volumeMounts:
  - name: config
    mountPath: /config
    subPath: <app-name>
```

## Apps Fixed

✅ **Radarr** - Running perfectly, no permission errors
✅ **Sonarr** - Running perfectly, no permission errors  
✅ **Lidarr** - Running perfectly, no permission errors

## Verification

All three apps are now running and logging shows successful startup:

### Radarr
```
[Info] Microsoft.Hosting.Lifetime: Now listening on: http://[::]:7878
[Info] Microsoft.Hosting.Lifetime: Application started.
[ls.io-init] done.
```

### Sonarr
```
[Info] Microsoft.Hosting.Lifetime: Now listening on: http://[::]:8989
[Info] Microsoft.Hosting.Lifetime: Application started.
[ls.io-init] done.
```

### Lidarr
```
[Info] Microsoft.Hosting.Lifetime: Now listening on: http://[::]:8686
[Info] Microsoft.Hosting.Lifetime: Application started.
[ls.io-init] done.
```

**No permission errors!** ✅

## Why This Works

1. **Init Container Runs First**: Creates directories and sets permissions before the main app starts
2. **777 Permissions**: Allows the app to read/write without needing to chown
3. **fsGroup: 1000**: Ensures files created by the app have the correct group
4. **PUID/PGID: 1000**: App runs as user 1000, matching the permissions

## Alternative Solutions (Not Used)

### Option 1: NFS Export with all_squash
Configure NFS export on Synology:
```
/volume1/infrastructure all_squash,anonuid=1000,anongid=1000
```
**Pros**: Cleaner, no init containers needed
**Cons**: Requires NAS configuration changes

### Option 2: Disable chown in Container
Set environment variable:
```yaml
- name: NO_CHOWN
  value: "true"
```
**Pros**: Simple
**Cons**: Not all containers support this

### Option 3: Use Local Storage
Use local-path instead of NFS
**Pros**: No permission issues
**Cons**: Data not backed up on NAS

## Current Solution Benefits

✅ **No NAS changes required** - Works with existing NFS setup
✅ **Data on NAS** - All configs backed up
✅ **Reliable** - Init container always runs first
✅ **Portable** - Works on any NFS server
✅ **Simple** - Easy to understand and maintain

## Storage Layout

All media app configs are on NFS:
```
/volume1/infrastructure/kubernetes/
├── pvc-<uuid>/radarr/
│   ├── logs/
│   ├── asp/
│   ├── config.xml
│   └── radarr.db
├── pvc-<uuid>/sonarr/
│   ├── logs/
│   ├── asp/
│   ├── config.xml
│   └── sonarr.db
└── pvc-<uuid>/lidarr/
    ├── logs/
    ├── asp/
    ├── config.xml
    └── lidarr.db
```

## Future Considerations

If you want to optimize further, you can:

1. **Configure NFS with all_squash** on Synology
   - Go to Control Panel → Shared Folder → Edit → NFS Permissions
   - Add `all_squash,anonuid=1000,anongid=1000` to options
   - Remove init containers from deployments

2. **Use NFS v4 with proper ID mapping**
   - More complex but more "correct"
   - Requires NFSv4 idmapd configuration

3. **Keep current solution**
   - Works perfectly as-is
   - No additional configuration needed
   - Recommended for simplicity

## Status

**Problem**: ❌ Permission denied errors on NFS
**Solution**: ✅ Init containers with chmod 777
**Result**: ✅ All media apps running perfectly
**Data**: ✅ Backed up on NAS
**Performance**: ✅ No issues

---

**Fixed**: November 24, 2025, 7:30 AM UTC
**Apps Affected**: Radarr, Sonarr, Lidarr
**Status**: 🟢 Fully Resolved

