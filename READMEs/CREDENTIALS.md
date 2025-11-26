# Homelab Kubernetes Credentials

## ⚠️ IMPORTANT: Change These Default Passwords!

All default passwords should be changed after initial deployment for security.

## Database Credentials

### PostgreSQL (Core Database)
- **Host**: `postgresql.core.svc.cluster.local:5432`
- **Admin User**: `postgres`
- **Admin Password**: `postgres123`
- **Location**: Local storage on control plane node (not on NAS)

### Application Databases

All applications share the same PostgreSQL instance with separate databases:

| Application | Database | Username | Password |
|------------|----------|----------|----------|
| Airbyte | airbyte | airbyte | airbyte123 |
| MLflow | mlflow | mlflow | mlflow123 |
| Nessie | nessie | nessie | nessie123 |
| Superset | superset | superset | superset123 |
| Grafana | grafana | grafana | grafana123 |
| n8n | n8n | n8n | n8n123 |
| Gitea | gitea | gitea | gitea123 |
| Vaultwarden | vaultwarden | vaultwarden | vaultwarden123 |

**Connection String Format:**
```
postgresql://<username>:<password>@postgresql.core.svc.cluster.local:5432/<database>
```

## Application Web Interfaces

### Media Management Apps

**Radarr** (Movies)
- URL: http://radarr.theblacklodge.dev
- Initial setup required on first access
- No default password - set during first run

**Sonarr** (TV Shows)
- URL: http://sonarr.theblacklodge.dev
- Initial setup required on first access
- No default password - set during first run

**Lidarr** (Music)
- URL: http://lidarr.theblacklodge.dev
- Initial setup required on first access
- No default password - set during first run

**Prowlarr** (Indexer Manager)
- URL: http://prowlarr.theblacklodge.dev
- Initial setup required on first access
- No default password - set during first run

**qBittorrent** (Download Client)
- URL: http://qbittorrent.theblacklodge.dev
- Default Username: `admin`
- Default Password: Check logs with: `kubectl logs -n apps <qbittorrent-pod> | grep "temporary password"`
- **IMPORTANT**: Change password immediately after first login

**Overseerr** (Request Management)
- URL: http://overseerr.theblacklodge.dev
- Initial setup required on first access
- Configure Radarr/Sonarr integration during setup

### Monitoring & Management

**Grafana** (Metrics & Dashboards)
- URL: http://grafana.theblacklodge.dev
- Username: `admin`
- Password: `admin123`
- Database: PostgreSQL (grafana database)

**pgAdmin** (Database Management)
- URL: http://pgadmin.theblacklodge.dev
- Email: `admin@theblacklodge.dev`
- Password: `admin123`
- Add PostgreSQL server with:
  - Host: `postgresql.core.svc.cluster.local`
  - Port: `5432`
  - Username: `postgres`
  - Password: `postgres123`

### Development & Automation

**Gitea** (Git Repository)
- URL: http://gitea.theblacklodge.dev
- Initial setup wizard on first access
- Database: PostgreSQL (gitea database)
- Admin account created during setup

**n8n** (Workflow Automation)
- URL: http://n8n.theblacklodge.dev
- Initial setup required on first access
- Database: PostgreSQL (n8n database)
- Create owner account during first run

**Vaultwarden** (Password Manager)
- URL: http://vaultwarden.theblacklodge.dev
- No default admin - create account on first access
- Database: PostgreSQL (vaultwarden database)
- Admin panel token: `admin123token`

### Data Platform

**Nessie** (Data Catalog)
- URL: http://nessie.theblacklodge.dev:19120
- No authentication by default
- Database: PostgreSQL (nessie database)

**Superset** (Data Visualization)
- URL: http://superset.theblacklodge.dev
- Username: `admin`
- Password: `admin`
- Database: PostgreSQL (superset database)

**MLflow** (ML Tracking)
- URL: http://mlflow.theblacklodge.dev
- No authentication by default
- Artifacts stored on NAS

## Infrastructure Access

### Kubernetes Cluster

**Control Plane**
- IP: `192.168.50.15`
- SSH: `ssh root@192.168.50.15`
- kubectl: Use kubeconfig from `/etc/rancher/k3s/k3s.yaml`

**Worker Nodes**
- Node 2: `192.168.50.16`
- Node 3: `192.168.50.17`

### NAS Storage

**Synology NAS**
- IP: `192.168.1.131`
- Web UI: http://192.168.1.131:5000
- Admin credentials: (your Synology admin account)

**NFS Shares**
- Infrastructure: `/volume1/infrastructure/kubernetes`
- Media: `/volume1/media`

## Storage Locations

### Application Data (NFS - Backed up via NAS)
```
/volume1/infrastructure/kubernetes/
├── pvc-<uuid>/gitea/          # Gitea repositories and data
├── pvc-<uuid>/prowlarr/       # Prowlarr configuration
├── pvc-<uuid>/lidarr/         # Lidarr configuration
├── pvc-<uuid>/radarr/         # Radarr configuration
├── pvc-<uuid>/sonarr/         # Sonarr configuration
├── pvc-<uuid>/qbittorrent/    # qBittorrent configuration
├── pvc-<uuid>/overseerr/      # Overseerr configuration
├── pvc-<uuid>/vaultwarden/    # Vaultwarden vault data
├── pvc-<uuid>/n8n/            # n8n workflows
├── pvc-<uuid>/pgadmin/        # pgAdmin configuration
├── pvc-<uuid>/grafana/        # Grafana dashboards
├── pvc-<uuid>/mlflow/         # MLflow artifacts
└── pvc-<uuid>/superset/       # Superset data
```

### Media Files (NFS - Backed up via NAS)
```
/volume1/media/
└── pvc-<uuid>/                # Shared media storage
    ├── Downloads/             # qBittorrent downloads
    ├── Movies/                # Radarr movies
    ├── TV/                    # Sonarr TV shows
    └── Music/                 # Lidarr music
```

### PostgreSQL Data (Local Storage - NOT on NAS)
```
/var/lib/rancher/k3s/storage/  # On control plane node
└── pvc-<uuid>/                # PostgreSQL data directory
```

**⚠️ Important**: PostgreSQL is on local storage for performance. Back it up separately:
```bash
kubectl exec -n core <postgresql-pod> -- pg_dumpall -U postgres > backup.sql
```

## Security Recommendations

### Immediate Actions
1. ✅ Change all default passwords listed above
2. ✅ Set up TLS/HTTPS for all ingresses (cert-manager is installed)
3. ✅ Configure firewall rules to restrict access
4. ✅ Enable authentication on services that don't have it (MLflow, Nessie)
5. ✅ Rotate the Vaultwarden admin token

### Backup Strategy
1. **NAS Snapshots**: Configure automatic snapshots for `/volume1/infrastructure` and `/volume1/media`
2. **PostgreSQL Dumps**: Set up automated database backups
3. **Kubernetes Configs**: Keep this repository backed up
4. **Test Restores**: Periodically test restoring from backups

### Access Control
1. Use Traefik middleware for authentication
2. Consider implementing OAuth2 proxy for SSO
3. Use network policies to restrict pod-to-pod communication
4. Enable RBAC for kubectl access

## Quick Reference Commands

### Check Application Status
```bash
kubectl get pods --all-namespaces
kubectl get pvc --all-namespaces
kubectl get ingress --all-namespaces
```

### View Application Logs
```bash
kubectl logs -n apps <pod-name>
kubectl logs -n apps <pod-name> --previous  # Previous container logs
```

### Access PostgreSQL
```bash
kubectl exec -it -n core <postgresql-pod> -- psql -U postgres
```

### Restart an Application
```bash
kubectl rollout restart deployment/<app-name> -n <namespace>
```

### Check NFS Mounts
```bash
kubectl get pv
kubectl describe pvc <pvc-name> -n <namespace>
```

## Support & Documentation

- **Main Docs**: See `REDEPLOYMENT_STATUS.md` for deployment details
- **NFS Issues**: See `FIX_NFS_EXPORTS.md` for troubleshooting
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **K3s Docs**: https://docs.k3s.io/

---

**Last Updated**: November 24, 2025
**Cluster Version**: K3s v1.33.5
