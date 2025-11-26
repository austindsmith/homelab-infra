# Quick Start Guide - Kubernetes Applications

## TL;DR - Get Everything Running

```bash
cd /mnt/secondary_ssd/Code/homelab/infra

# 1. Setup kubectl access (if needed)
./scripts/setup-kubectl-access.sh

# 2. Deploy everything
./scripts/deploy-fixed-apps.sh

# 3. Check health
./scripts/check-app-health.sh

# 4. (Optional) Cleanup old resources
./scripts/cleanup-old-resources.sh
```

## What This Does

✅ Deploys all your applications with proper NAS storage  
✅ Each app gets its own folder at `/volume1/infrastructure/kubernetes/<app-name>`  
✅ All apps using PostgreSQL connect to a single consolidated instance  
✅ Media apps share storage at `/volume1/media`  
✅ All apps have health checks and proper resource limits  

## Applications Deployed

### Media Stack
- **Radarr** (Movies) - http://radarr.theblacklodge.dev
- **Sonarr** (TV) - http://sonarr.theblacklodge.dev
- **Lidarr** (Music) - http://lidarr.theblacklodge.dev
- **Prowlarr** (Indexers) - http://prowlarr.theblacklodge.dev
- **qBittorrent** (Downloads) - http://qbittorrent.theblacklodge.dev
- **Overseerr** (Requests) - http://overseerr.theblacklodge.dev

### Datalake Stack
- **Airbyte** (Data Integration)
- **Dremio** (Data Lakehouse)
- **MLflow** (ML Tracking)
- **Spark** (Distributed Computing) - http://spark.theblacklodge.dev
- **Superset** (Visualization)
- **Nessie** (Data Catalog)

### Other Apps
- **Grafana** (Monitoring) - http://grafana.theblacklodge.dev
- **Gitea** (Git) - http://gitea.theblacklodge.dev
- **Vaultwarden** (Passwords) - http://vaultwarden.theblacklodge.dev
- **pgAdmin** (Database) - http://pgadmin.theblacklodge.dev
- **n8n** (Automation) - http://n8n.theblacklodge.dev

## Storage Layout

```
/volume1/infrastructure/kubernetes/
├── postgresql/          # All databases
├── radarr/             # Movie configs
├── sonarr/             # TV configs
├── lidarr/             # Music configs
├── prowlarr/           # Indexer configs
├── qbittorrent/        # Download client configs
├── overseerr/          # Request configs
├── airbyte/            # Data integration
├── dremio/             # Data lakehouse
├── mlflow/             # ML tracking
├── spark/              # Spark work dir
├── superset/           # Visualization
├── grafana/            # Dashboards
├── gitea/              # Git repos
├── vaultwarden/        # Password vault
├── pgadmin/            # DB admin
└── n8n/                # Workflows

/volume1/media/
├── Downloads/          # qBittorrent downloads
├── Movies/             # Radarr movies
├── TV/                 # Sonarr TV shows
└── Music/              # Lidarr music
```

## Default Credentials

**⚠️ CHANGE THESE IN PRODUCTION!**

| App | Username | Password |
|-----|----------|----------|
| PostgreSQL | postgres | postgres123 |
| Grafana | admin | admin123 |
| pgAdmin | admin@theblacklodge.dev | admin123 |
| Superset | admin | admin |

## Troubleshooting

### Pod won't start?
```bash
# Check status
kubectl get pods -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Can't access web interface?
```bash
# Check if ingress is configured
kubectl get ingress --all-namespaces

# Or use NodePort
kubectl get svc --all-namespaces | grep NodePort
```

### Storage issues?
```bash
# Check PVCs
kubectl get pvc --all-namespaces

# Check if NFS is accessible
# From a cluster node:
showmount -e 192.168.1.131
```

## Common Commands

```bash
# View all pods
kubectl get pods --all-namespaces

# View specific app
kubectl get pods -n apps -l app=radarr

# View logs
kubectl logs -n apps -l app=radarr --tail=50

# Restart an app
kubectl rollout restart deployment/radarr -n apps

# Scale an app
kubectl scale deployment/radarr -n apps --replicas=0  # Stop
kubectl scale deployment/radarr -n apps --replicas=1  # Start

# Delete and redeploy
kubectl delete -f k8s/apps/radarr/deployment.yaml
kubectl apply -f k8s/apps/radarr/deployment.yaml
```

## Next Steps

1. ✅ Deploy applications (done with deploy script)
2. 🔧 Configure DNS for ingress hostnames
3. 🔒 Change default passwords
4. 🔐 Set up TLS certificates
5. 🔗 Configure app integrations (Radarr → qBittorrent, etc.)
6. 📊 Set up Grafana dashboards
7. 💾 Configure NAS snapshots for backups

## Need More Help?

- **Full Documentation**: See `K8S_APPS_MIGRATION_COMPLETE.md`
- **Deployment Details**: See `DEPLOYMENT_SUMMARY.md`
- **Check Health**: Run `./scripts/check-app-health.sh`
- **Cleanup**: Run `./scripts/cleanup-old-resources.sh`

## Files You Care About

```
scripts/
├── setup-kubectl-access.sh      # Get kubectl working
├── deploy-fixed-apps.sh         # Deploy everything
├── check-app-health.sh          # Verify health
└── cleanup-old-resources.sh     # Clean up old stuff

k8s/
├── storage/                     # Storage classes and PVCs
├── core/postgresql/             # Central database
├── apps/                        # All applications
├── datalake/                    # Data platform apps
└── monitoring/                  # Monitoring stack
```

That's it! You're ready to go! 🚀

