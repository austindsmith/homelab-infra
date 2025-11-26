# Infrastructure Analysis & Improvement Guide

## Current Setup Overview

### Architecture
- **Hypervisor**: Proxmox VE
- **VMs**: 5 Ubuntu 20.04 VMs (2 servers, 3 agents)
- **Orchestration**: K3s Kubernetes cluster
- **GitOps**: ArgoCD for application deployment
- **Ingress**: Traefik with Cloudflare tunnels
- **Certificates**: cert-manager with Let's Encrypt DNS challenge

### Current Resource Allocation
- **Memory**: 2GB per VM (10GB total)
- **CPU**: 1 core per VM (5 cores total)
- **Storage**: 25GB per VM

## Identified Issues & Root Causes

### 1. Resource Underutilization
**Problem**: Low CPU/memory usage despite 2GB RAM allocation
**Root Causes**:
- K3s default resource limits are conservative
- No resource requests/limits set on applications
- Kubernetes scheduler not efficiently placing workloads
- Possible memory/CPU throttling at hypervisor level

### 2. Application Deployment Issues
**Problem**: Only ArgoCD, Homepage, and Lidarr working
**Root Causes**:
- Missing resource specifications in Helm charts
- Incomplete ingress configurations
- Potential DNS/networking issues
- Missing dependencies or persistent storage

### 3. Hostname/DNS Resolution Issues
**Problem**: Difficulty with hostname resolution through Cloudflare tunnels
**Root Causes**:
- Complex routing: Cloudflare → Cloud Gateway → nginx → Traefik
- Potential header forwarding issues
- SSL/TLS termination conflicts
- Missing or incorrect DNS records

### 4. Helm Chart Management
**Problem**: Inconsistent chart structure and deployment patterns
**Root Causes**:
- Mixed deployment methods (HelmChart CRDs vs ArgoCD Apps)
- Inconsistent values.yaml structure
- Missing Chart.yaml files for custom charts
- No standardized chart templates

## Recommended Solutions

### 1. Resource Optimization

#### Increase VM Resources
```hcl
# terraform/variables.tf
variable "vm_memory" {
  type    = number
  default = 4096  # Increase from 2048
}

variable "vm_cores" {
  type    = number
  default = 2     # Increase from 1
}
```

#### Add Resource Specifications to Applications
```yaml
# Example for all applications
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 2. Standardize Helm Chart Structure

#### Create Chart Template Structure
```
k8s/
├── _templates/
│   ├── Chart.yaml.template
│   ├── values.yaml.template
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── configmap.yaml
└── [app-name]/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

### 3. Fix Networking & DNS

#### Simplify Ingress Chain
- Remove nginx proxy manager layer
- Use Traefik directly with Cloudflare tunnels
- Configure proper header forwarding

#### Update Traefik Configuration
```yaml
# traefik-override.yml
entryPoints:
  websecure:
    address: ":443"
    forwardedHeaders:
      trustedIPs:
        - 173.245.48.0/20   # Cloudflare IPs
        - 103.21.244.0/22
        - 103.22.200.0/22
        - 103.31.4.0/22
        - 141.101.64.0/18
        - 108.162.192.0/18
        - 190.93.240.0/20
        - 188.114.96.0/20
        - 197.234.240.0/22
        - 198.41.128.0/17
        - 162.158.0.0/15
        - 104.16.0.0/13
        - 104.24.0.0/14
        - 172.64.0.0/13
        - 131.0.72.0/22
```

### 4. Improve Application Reliability

#### Add Health Checks
```yaml
# Add to all deployments
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
```

#### Add Persistent Storage
```yaml
# Add to stateful applications
persistence:
  enabled: true
  storageClass: "local-path"  # K3s default
  size: 10Gi
```

## Resource Planning

### Current vs Recommended Resources

| Component | Current | Recommended | Reason |
|-----------|---------|-------------|---------|
| VM Memory | 2GB | 4-6GB | K8s overhead + applications |
| VM CPU | 1 core | 2 cores | Better scheduling flexibility |
| Total Memory | 10GB | 20-30GB | Room for growth |
| Total CPU | 5 cores | 10 cores | Improved performance |

### Estimated Resource Requirements by Application

| Application | Memory | CPU | Storage | Notes |
|-------------|--------|-----|---------|-------|
| K3s System | 1GB | 0.5 cores | 5GB | Per node overhead |
| ArgoCD | 512MB | 0.2 cores | 2GB | GitOps controller |
| Traefik | 256MB | 0.1 cores | 1GB | Ingress controller |
| Grafana | 512MB | 0.2 cores | 5GB | Monitoring |
| N8N | 1GB | 0.3 cores | 10GB | Workflow automation |
| Homepage | 128MB | 0.1 cores | 1GB | Dashboard |
| Lidarr | 512MB | 0.2 cores | 20GB | Media management |

### Future Growth Planning
- **Short term (3-6 months)**: 6GB RAM, 2 cores per VM
- **Medium term (6-12 months)**: 8GB RAM, 3 cores per VM
- **Long term (1+ years)**: Consider dedicated storage nodes

## Implementation Roadmap

### Phase 1: Infrastructure Improvements (Week 1)
1. Update Terraform VM specifications
2. Recreate VMs with increased resources
3. Update Ansible playbooks for new resource allocation

### Phase 2: Networking & DNS (Week 2)
1. Simplify ingress chain
2. Update Traefik configuration
3. Fix Cloudflare tunnel routing
4. Test hostname resolution

### Phase 3: Application Standardization (Week 3-4)
1. Create standardized Helm chart templates
2. Update existing applications with proper resource specs
3. Add health checks and persistent storage
4. Migrate to consistent ArgoCD deployment pattern

### Phase 4: Monitoring & Optimization (Week 5-6)
1. Deploy comprehensive monitoring stack
2. Set up resource usage alerts
3. Optimize resource allocation based on actual usage
4. Document operational procedures

## Best Practices Moving Forward

### Terraform
- Use modules for reusable VM configurations
- Implement proper state management (remote backend)
- Add validation rules for resource limits
- Use data sources for dynamic configurations

### Ansible
- Implement proper secret management (Ansible Vault)
- Use roles for reusable configurations
- Add idempotency checks
- Implement proper error handling

### Kubernetes
- Always specify resource requests and limits
- Use namespaces for logical separation
- Implement proper RBAC
- Use ConfigMaps and Secrets for configuration

### ArgoCD
- Use App of Apps pattern for complex deployments
- Implement proper sync policies
- Use multiple repositories for separation of concerns
- Monitor sync status and health

## Troubleshooting Guide

### Common Issues and Solutions

#### Application Not Starting
1. Check resource availability: `kubectl top nodes`
2. Verify image pull: `kubectl describe pod <pod-name>`
3. Check logs: `kubectl logs <pod-name>`
4. Verify ingress: `kubectl get ingress -A`

#### DNS Resolution Issues
1. Test internal DNS: `nslookup kubernetes.default.svc.cluster.local`
2. Check CoreDNS: `kubectl logs -n kube-system -l k8s-app=kube-dns`
3. Verify external DNS: `dig @1.1.1.1 your-domain.com`

#### Certificate Issues
1. Check cert-manager: `kubectl get certificates -A`
2. Verify DNS challenge: `kubectl describe challenge <challenge-name>`
3. Check Cloudflare API permissions
4. Verify DNS records

This analysis provides a comprehensive roadmap for improving your infrastructure. Focus on the resource allocation first, as this is likely the primary cause of your current issues.
