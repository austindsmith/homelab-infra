# Kubernetes Applications Migration - Complete

## Overview

All Kubernetes applications have been updated to use proper NAS storage at `/volume1/infrastructure/kubernetes` with individual folders for each application. PostgreSQL has been consolidated into a single instance with multiple databases.

## Storage Architecture

### NAS Storage Classes

- **nfs-infrastructure**: For application configs and databases at `/volume1/infrastructure/kubernetes`
- **nfs-media**: For media files at `/volume1/media`

### Application Storage Layout

Each application now has its own dedicated folder on the NAS:

```
/volume1/infrastructure/kubernetes/
├── postgresql/          # PostgreSQL data directory
├── radarr/             # Radarr configuration
├── sonarr/             # Sonarr configuration
├── lidarr/             # Lidarr configuration
├── prowlarr/           # Prowlarr configuration
├── qbittorrent/        # qBittorrent configuration
├── overseerr/          # Overseerr configuration
├── airbyte/            # Airbyte configs and workspace
├── dremio/             # Dremio data
├── mlflow/             # MLflow artifacts
├── spark/              # Spark work directory
├── superset/           # Superset data
├── grafana/            # Grafana data
├── gitea/              # Gitea data and repos
├── vaultwarden/        # Vaultwarden data
├── pgadmin/            # pgAdmin configuration
└── n8n/                # n8n workflows and data
```

### Media Storage Layout

```
/volume1/media/
├── Downloads/          # qBittorrent downloads
├── Movies/             # Radarr movies
├── TV/                 # Sonarr TV shows
└── Music/              # Lidarr music
```

## PostgreSQL Consolidation

All applications now use a single PostgreSQL instance running in the `core` namespace with separate databases:

### Database Configuration

| Application | Database | User | Password |
|------------|----------|------|----------|
| Airbyte | airbyte | airbyte | airbyte123 |
| MLflow | mlflow | mlflow | mlflow123 |
| Nessie | nessie | nessie | nessie123 |
| Superset | superset | superset | superset123 |
| Grafana | grafana | grafana | grafana123 |
| n8n | n8n | n8n | n8n123 |
| Gitea | gitea | gitea | gitea123 |
| Vaultwarden | vaultwarden | vaultwarden | vaultwarden123 |

**Note**: Change these default passwords in production!

### PostgreSQL Connection String Format

```
postgresql://<user>:<password>@postgresql.core.svc.cluster.local:5432/<database>
```

## Applications Fixed

### Media Applications (namespace: apps)

1. **Radarr** - Movie management
   - Port: 7878
   - Storage: 5Gi config + shared media
   - Health endpoint: `/ping`

2. **Sonarr** - TV show management
   - Port: 8989
   - Storage: 5Gi config + shared media
   - Health endpoint: `/ping`

3. **Lidarr** - Music management
   - Port: 8686
   - Storage: 5Gi config + shared media
   - Health endpoint: `/ping`

4. **Prowlarr** - Indexer manager
   - Port: 9696
   - Storage: 2Gi config
   - Health endpoint: `/ping`

5. **qBittorrent** - Torrent client
   - Port: 8080 (web), 6881 (torrent)
   - Storage: 2Gi config + shared media
   - Health endpoint: `/`

6. **Overseerr** - Request management
   - Port: 5055
   - Storage: 2Gi config
   - Health endpoint: `/api/v1/status`

### Datalake Applications (namespace: datalake)

1. **Airbyte** - Data integration
   - Ports: 80 (webapp), 8001 (server)
   - Storage: 10Gi for configs and workspace
   - Database: PostgreSQL
   - Health endpoint: `/api/v1/health`

2. **Dremio** - Data lakehouse
   - Ports: 9047 (web), 31010 (client), 45678 (server)
   - Storage: 20Gi for data
   - Health endpoint: `/`

3. **MLflow** - ML experiment tracking
   - Port: 5000
   - Storage: 50Gi for artifacts
   - Database: PostgreSQL
   - Health endpoint: `/health`

4. **Spark** - Distributed computing
   - Master: 7077 (spark), 8080 (web)
   - Worker: 8081 (web)
   - Storage: 20Gi shared work directory
   - Health endpoint: `/`

5. **Superset** - Data visualization
   - Port: 8088
   - Storage: 10Gi for data
   - Database: PostgreSQL
   - Health endpoint: `/health`

6. **Nessie** - Data catalog
   - Port: 19120
   - Database: PostgreSQL (no local storage needed)
   - Health endpoint: `/api/v1/config`

### Monitoring Applications (namespace: monitoring)

1. **Grafana** - Metrics visualization
   - Port: 3000
   - Storage: 10Gi for dashboards
   - Database: PostgreSQL
   - Health endpoint: `/api/health`

### Other Applications (namespace: apps)

1. **Gitea** - Git repository hosting
   - Ports: 3000 (web), 22 (ssh)
   - Storage: 20Gi for repos and data
   - Database: PostgreSQL
   - Health endpoint: `/api/healthz`

2. **Vaultwarden** - Password manager
   - Port: 80
   - Storage: 5Gi for data
   - Database: PostgreSQL
   - Health endpoint: `/alive`

3. **pgAdmin** - PostgreSQL management
   - Port: 80
   - Storage: 2Gi for config
   - Health endpoint: `/misc/ping`

4. **n8n** - Workflow automation
   - Port: 5678
   - Storage: 10Gi for workflows
   - Database: PostgreSQL
   - Health endpoint: `/healthz`

## Deployment Instructions

### Prerequisites

1. Ensure you have kubectl configured and can access your cluster
2. Verify NFS storage is accessible at the configured paths
3. Backup any existing data before proceeding

### Step 1: Deploy Storage

```bash
cd /mnt/secondary_ssd/Code/homelab/infra

# Apply storage classes
kubectl apply -f k8s/storage/nfs-storage-classes.yaml

# Apply media storage PVC
kubectl apply -f k8s/storage/media-storage.yaml
```

### Step 2: Deploy PostgreSQL

```bash
# Create core namespace
kubectl create namespace core

# Deploy PostgreSQL with init scripts
kubectl apply -f k8s/core/postgresql/init-databases.yaml
kubectl apply -f k8s/core/postgresql/deployment.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgresql -n core --timeout=300s
```

### Step 3: Deploy All Applications

Use the automated deployment script:

```bash
cd scripts
./deploy-fixed-apps.sh
```

Or deploy manually by namespace:

```bash
# Media apps
kubectl apply -f k8s/apps/radarr/deployment.yaml
kubectl apply -f k8s/apps/sonarr/deployment.yaml
kubectl apply -f k8s/apps/lidarr/deployment.yaml
kubectl apply -f k8s/apps/prowlarr/deployment.yaml
kubectl apply -f k8s/apps/qbittorrent/deployment.yaml
kubectl apply -f k8s/apps/overseerr/deployment.yaml

# Datalake apps
kubectl apply -f k8s/datalake/airbyte/deployment.yaml
kubectl apply -f k8s/datalake/dremio/deployment.yaml
kubectl apply -f k8s/datalake/mlflow/deployment.yaml
kubectl apply -f k8s/datalake/spark/deployment.yaml
kubectl apply -f k8s/datalake/superset/deployment.yaml
kubectl apply -f k8s/datalake/nessie/deployment.yaml

# Monitoring apps
kubectl apply -f k8s/monitoring/grafana/deployment.yaml

# Other apps
kubectl apply -f k8s/apps/gitea/deployment.yaml
kubectl apply -f k8s/apps/vaultwarden/deployment.yaml
kubectl apply -f k8s/apps/pgadmin/deployment.yaml
kubectl apply -f k8s/apps/n8n/deployment.yaml
```

### Step 4: Verify Deployment

```bash
# Check all pods
kubectl get pods --all-namespaces

# Run health check script
cd scripts
./check-app-health.sh
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**
   - Check PVC status: `kubectl get pvc --all-namespaces`
   - Verify NFS server is accessible
   - Check storage class provisioner is running

2. **Pods in CrashLoopBackOff**
   - Check logs: `kubectl logs <pod-name> -n <namespace>`
   - Verify database connectivity for apps using PostgreSQL
   - Check resource limits and available cluster resources

3. **Database Connection Issues**
   - Verify PostgreSQL is running: `kubectl get pods -n core`
   - Check PostgreSQL logs: `kubectl logs -n core -l app=postgresql`
   - Verify database was created: `kubectl exec -n core -it <postgres-pod> -- psql -U postgres -l`

4. **Storage Permission Issues**
   - Check pod security context (fsGroup)
   - Verify NFS permissions on the NAS
   - Check subPath configuration in volume mounts

### Accessing Applications

All applications are accessible via their ingress hostnames:

- Radarr: http://radarr.theblacklodge.dev
- Sonarr: http://sonarr.theblacklodge.dev
- Lidarr: http://lidarr.theblacklodge.dev
- Prowlarr: http://prowlarr.theblacklodge.dev
- qBittorrent: http://qbittorrent.theblacklodge.dev
- Overseerr: http://overseerr.theblacklodge.dev
- Grafana: http://grafana.theblacklodge.dev
- Gitea: http://gitea.theblacklodge.dev
- Vaultwarden: http://vaultwarden.theblacklodge.dev
- pgAdmin: http://pgadmin.theblacklodge.dev
- n8n: http://n8n.theblacklodge.dev
- Spark: http://spark.theblacklodge.dev

Or via NodePort services on the cluster nodes.

## Maintenance

### Backup Strategy

1. **Application Data**: Backed up via NAS snapshots of `/volume1/infrastructure/kubernetes`
2. **PostgreSQL**: Regular dumps recommended
   ```bash
   kubectl exec -n core <postgres-pod> -- pg_dumpall -U postgres > backup.sql
   ```
3. **Media Files**: Backed up via NAS snapshots of `/volume1/media`

### Monitoring

- Use Grafana for metrics visualization
- Check pod health regularly with `./check-app-health.sh`
- Monitor NAS storage usage

### Cleanup

Run the cleanup script to identify unused resources:

```bash
cd scripts
./cleanup-old-resources.sh
```

## Resource Requirements

### Minimum Cluster Resources

- **CPU**: 8 cores minimum (12+ recommended)
- **Memory**: 16GB minimum (32GB+ recommended)
- **Storage**: 
  - NFS infrastructure: 200GB minimum
  - NFS media: 1TB+ recommended

### Per-Application Resources

See individual deployment files for specific resource requests and limits.

## Security Considerations

1. **Change Default Passwords**: All default passwords should be changed in production
2. **Network Policies**: Consider implementing network policies to restrict pod-to-pod communication
3. **Secrets Management**: Move passwords from environment variables to Kubernetes Secrets
4. **TLS/SSL**: Configure cert-manager for HTTPS on all ingresses
5. **RBAC**: Implement proper role-based access control

## Next Steps

1. Configure DNS for ingress hostnames
2. Set up TLS certificates via cert-manager
3. Configure backup automation
4. Set up monitoring alerts
5. Implement proper secrets management
6. Configure media app integrations (Radarr → qBittorrent, etc.)
7. Set up Grafana dashboards for monitoring

## Support

For issues or questions:
1. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
2. Check events: `kubectl get events -n <namespace>`
3. Review this documentation
4. Check application-specific documentation

## Changelog

### 2024-11-24 - Initial Migration

- Migrated all applications to use individual NFS-backed PVCs
- Consolidated PostgreSQL into single instance with multiple databases
- Added health probes to all deployments
- Created deployment and health check scripts
- Documented complete storage architecture

