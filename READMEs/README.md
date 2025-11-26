# 🏠 Homelab Infrastructure

Complete infrastructure-as-code for a production-grade homelab running Kubernetes (K3s) on Proxmox with comprehensive application stacks.

## 🚀 Quick Start

```bash
# 1. Create VMs with Terraform
cd terraform
terraform init && terraform apply

# 2. Deploy K3s cluster with Ansible
cd ../ansible
./deploy.sh

# 3. Access your cluster
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

For detailed setup instructions, see [Quick Start Guide](READMEs/deployment/QUICK_START.md).

## 📋 What's Included

### 🏗️ Infrastructure
- **Hypervisor**: Proxmox VE
- **VMs**: 3 Ubuntu nodes (1 control plane + 2 workers)
- **Orchestration**: K3s Kubernetes
- **GitOps**: ArgoCD for application deployment
- **Ingress**: Traefik with Let's Encrypt certificates
- **Storage**: NFS from Synology NAS

### 📦 Application Stacks

**Core Services**
- ArgoCD (GitOps), Traefik (Ingress), cert-manager (TLS)
- PostgreSQL (Shared database), pgAdmin (DB management)
- Homepage (Dashboard)

**Monitoring & Observability**
- Prometheus, Grafana, Loki, Promtail

**Data Lakehouse Platform**
- MinIO (Object Storage), Nessie (Catalog)
- Dremio (Query Engine), Airbyte (Data Integration)
- Apache Spark (Processing), JupyterHub (Notebooks)
- MLflow (ML Tracking), Superset (Analytics)

**Media Management**
- Radarr (Movies), Sonarr (TV), Lidarr (Music)
- Prowlarr (Indexers), Overseerr (Requests)
- qBittorrent (Downloads)

**Development & Automation**
- Gitea (Git hosting), n8n (Workflow automation)
- Vaultwarden (Password manager)

## 📚 Documentation

### 🎯 Start Here
- **[Complete User Guide](READMEs/USER_GUIDE.md)** - ⭐ **Comprehensive guide to all applications**
  - How to use every app in your homelab
  - Complete data lakehouse workflows
  - Step-by-step tutorials and examples
  - Project ideas and use cases

### 🏗️ Infrastructure
- [Talos Migration](READMEs/infrastructure/TALOS_MIGRATION.md) - Migrate to Talos Linux for better efficiency
- [NAS Integration](READMEs/infrastructure/NAS_INTEGRATION_GUIDE.md) - NFS storage setup
- [Resource Planning](READMEs/infrastructure/RESOURCE_PLANNING.md) - Capacity planning
- [Complete Rebuild](READMEs/infrastructure/COMPLETE_REBUILD_GUIDE.md) - Rebuild from scratch
- [Credential Management](READMEs/infrastructure/CREDENTIAL_MANAGEMENT.md) - Security best practices

### 🚀 Deployment
- [Quick Start](READMEs/deployment/QUICK_START.md) - Get started fast
- [Infrastructure Setup](READMEs/deployment/QUICKSTART_INFRASTRUCTURE.md) - Detailed infrastructure deployment
- [Networking & DNS](READMEs/deployment/NETWORKING_DNS_GUIDE.md) - Network architecture
- [Helm Charts](READMEs/deployment/HELM_CHART_GUIDE.md) - Standardized deployments

### 💻 Development
- [Ansible Guide](READMEs/development/ANSIBLE_DEVELOPMENT_GUIDE.md) - Ansible best practices
- [K8s Development](READMEs/development/K8S_DEVELOPMENT_GUIDE.md) - Kubernetes workflow
- [Testing Strategy](READMEs/development/TESTING_VALIDATION_STRATEGY.md) - Validation approaches

### 📊 Projects
- [Data Lakehouse Setup](READMEs/projects/DATALAKE_5DAY_SETUP.md) - Complete data platform
- [Deployment Summary](READMEs/projects/DEPLOYMENT_SUMMARY.md) - Current deployment state
- [K8s Apps Migration](READMEs/projects/K8S_APPS_MIGRATION_COMPLETE.md) - Application migration details
- [Media Apps Guide](READMEs/projects/MEDIA_APPS_MIGRATION_GUIDE.md) - Media stack setup

## 📁 Repository Structure

```
.
├── terraform/              # Infrastructure provisioning
│   ├── main.tf            # Main K3s infrastructure
│   ├── talos/             # Talos Linux configs (alternative)
│   └── archive/           # Old configurations
├── ansible/               # Configuration management
│   ├── site.yml           # Main playbook
│   ├── applications/      # App deployment playbooks
│   ├── configurations/    # System configs
│   └── inventory.ini      # Host inventory
├── k8s/                   # Kubernetes manifests
│   ├── core/             # Core infrastructure
│   ├── monitoring/       # Monitoring stack
│   ├── datalake/         # Data lakehouse apps
│   ├── apps/             # General applications
│   └── storage/          # Storage configurations
├── scripts/              # Utility scripts
├── READMEs/              # Documentation
│   ├── infrastructure/   # Infrastructure docs
│   ├── deployment/       # Deployment guides
│   ├── development/      # Development guides
│   └── projects/         # Project documentation
└── CREDENTIALS.md        # Access credentials (KEEP SECURE!)
```

## 🔐 Credentials & Access

**Important**: See [CREDENTIALS.md](CREDENTIALS.md) for all application passwords and access details.

Common access points:
- **ArgoCD**: https://argocd.theblacklodge.dev
- **Grafana**: https://grafana.theblacklodge.dev
- **Homepage**: https://homepage.theblacklodge.dev
- **Proxmox**: https://proxmox.theblacklodge.org:8006

## 🛠️ Common Operations

### Infrastructure Management

```bash
# Create/update VMs
cd terraform && terraform apply

# Deploy K3s cluster
cd ansible && ansible-playbook site.yml

# Install specific application
cd ansible && ansible-playbook applications/k3s-apps.yml
```

### Kubernetes Operations

```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A

# Deploy application
kubectl apply -f k8s/apps/app-name/

# View logs
kubectl logs -f deployment/app-name -n namespace

# Access services
kubectl port-forward svc/service-name -n namespace 8080:80
```

### Monitoring & Debugging

```bash
# Use K9s for interactive management
k9s

# Check resource usage
kubectl top nodes
kubectl top pods -A

# View events
kubectl get events -A --sort-by='.lastTimestamp'

# Check specific pod
kubectl describe pod pod-name -n namespace
```

## 💾 Backup & Recovery

### Important Data Locations

- **NAS Storage**: `/volume1/infrastructure/kubernetes/` (all app data)
- **Media Storage**: `/volume1/media/` (media files)
- **Kubeconfig**: `/etc/rancher/k3s/k3s.yaml` on control plane
- **Terraform State**: `terraform/terraform.tfstate`

### Backup Strategy

1. **NAS Snapshots**: Automated via Synology
2. **Kubernetes Manifests**: Version controlled in Git
3. **Credentials**: Stored securely (see CREDENTIALS.md)
4. **Terraform State**: Backed up regularly

## 🔧 Troubleshooting

### Cluster Issues

```bash
# Restart K3s service
ssh austin@192.168.50.15 'sudo systemctl restart k3s'

# Check K3s logs
ssh austin@192.168.50.15 'sudo journalctl -u k3s -f'

# Verify network connectivity
ansible all -m ping
```

### Application Issues

```bash
# Check pod status
kubectl get pods -n namespace

# View pod logs
kubectl logs pod-name -n namespace

# Restart deployment
kubectl rollout restart deployment/app-name -n namespace

# Check ingress
kubectl get ingress -A
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -A

# Verify NFS mount
ssh austin@192.168.50.15 'mount | grep nfs'

# Test NFS connectivity
kubectl run -it --rm nfs-test --image=busybox -- sh
# Inside pod: mount -t nfs nas.theblacklodge.org:/volume1/infrastructure/kubernetes /mnt
```

## 📊 Resource Requirements

### Current Setup
- **VMs**: 3 nodes (1 control + 2 workers)
- **Memory**: 8GB per VM (24GB total)
- **CPU**: 4 cores per VM (12 cores total)
- **Storage**: 100GB per VM (300GB total)

### Recommended Minimum
- **Memory**: 6GB per VM (18GB total)
- **CPU**: 2 cores per VM (6 cores total)
- **Storage**: 50GB per VM (150GB total)

## 🎯 Future Enhancements

- [ ] Migrate to Talos Linux for reduced memory footprint
- [ ] Implement automated backups with Velero
- [ ] Add service mesh (Istio/Linkerd)
- [ ] Expand monitoring with Thanos
- [ ] Implement disaster recovery procedures

## 📝 Notes

- This infrastructure uses K3s (lightweight Kubernetes) instead of full K8s
- All applications use NFS storage from Synology NAS
- TLS certificates are automatically managed by cert-manager
- GitOps workflow via ArgoCD for application deployment
- Network traffic flows: Internet → Cloudflare → nginx-proxy-manager → Traefik → Apps

## 🤝 Contributing

This is a personal homelab project, but feel free to use it as reference for your own infrastructure!

## 📄 License

MIT License - Use at your own risk
