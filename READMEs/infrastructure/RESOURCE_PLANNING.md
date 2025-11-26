# Resource Planning & Capacity Guide

## Current Resource Analysis

### VM Resource Allocation (Current)
- **Memory**: 2GB per VM × 5 VMs = 10GB total
- **CPU**: 1 core per VM × 5 VMs = 5 cores total
- **Storage**: 25GB per VM × 5 VMs = 125GB total

### Observed Issues
1. **Low Resource Utilization**: Despite 2GB allocation, VMs show minimal memory usage
2. **CPU Underutilization**: Cores are barely being used
3. **Application Failures**: Some apps not starting due to resource constraints
4. **Kubernetes Overhead**: K3s system components consuming significant resources

## Root Cause Analysis

### Why Resources Appear Unused

#### 1. Kubernetes Resource Management
```bash
# Check actual resource requests vs limits
kubectl describe nodes
kubectl top nodes
kubectl top pods -A
```

**Problem**: Without resource requests/limits, Kubernetes doesn't know how to schedule workloads efficiently.

#### 2. Memory Allocation Issues
- **Linux Memory Management**: Linux caches aggressively, making memory appear "used"
- **Container Limits**: Without proper limits, containers can't utilize available memory
- **K3s Overhead**: Base K3s installation uses ~512MB per node

#### 3. CPU Scheduling Problems
- **Single Core Limitation**: 1 core limits concurrent processing
- **Context Switching**: Frequent switching between processes on single core
- **Kubernetes Scheduler**: Can't efficiently distribute workloads

## Recommended Resource Allocation

### Phase 1: Immediate Improvements (Next Week)
```hcl
# terraform/variables.tf updates
variable "vm_memory" {
  type    = number
  default = 4096  # Double current allocation
}

variable "vm_cores" {
  type    = number
  default = 2     # Double current allocation
}
```

**Total Resources**: 20GB RAM, 10 CPU cores

### Phase 2: Medium-term Growth (3-6 months)
```hcl
variable "vm_memory" {
  type    = number
  default = 6144  # 6GB per VM
}

variable "vm_cores" {
  type    = number
  default = 3     # 3 cores per VM
}
```

**Total Resources**: 30GB RAM, 15 CPU cores

### Phase 3: Long-term Planning (6-12 months)
```hcl
variable "vm_memory" {
  type    = number
  default = 8192  # 8GB per VM
}

variable "vm_cores" {
  type    = number
  default = 4     # 4 cores per VM
}
```

**Total Resources**: 40GB RAM, 20 CPU cores

## Application Resource Requirements

### System Components (Per Node)
| Component | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|----------------|--------------|-------------|-----------|
| K3s Server | 512Mi | 1Gi | 200m | 500m |
| K3s Agent | 256Mi | 512Mi | 100m | 300m |
| Traefik | 128Mi | 256Mi | 50m | 200m |
| CoreDNS | 64Mi | 128Mi | 50m | 100m |
| Metrics Server | 64Mi | 128Mi | 50m | 100m |

### Application Components
| Application | Memory Request | Memory Limit | CPU Request | CPU Limit | Storage |
|-------------|----------------|--------------|-------------|-----------|---------|
| ArgoCD Server | 256Mi | 512Mi | 100m | 500m | 2Gi |
| ArgoCD Repo Server | 256Mi | 512Mi | 100m | 500m | 2Gi |
| ArgoCD Controller | 512Mi | 1Gi | 250m | 1000m | 2Gi |
| Grafana | 256Mi | 512Mi | 100m | 500m | 10Gi |
| N8N | 512Mi | 1Gi | 200m | 1000m | 20Gi |
| Homepage | 64Mi | 128Mi | 50m | 200m | 1Gi |
| Lidarr | 256Mi | 512Mi | 100m | 500m | 50Gi |
| cert-manager | 128Mi | 256Mi | 100m | 300m | 1Gi |

### Future Applications (Planning)
| Application | Memory Request | Memory Limit | CPU Request | CPU Limit | Storage |
|-------------|----------------|--------------|-------------|-----------|---------|
| Prometheus | 1Gi | 2Gi | 500m | 2000m | 100Gi |
| Loki | 512Mi | 1Gi | 200m | 1000m | 50Gi |
| Jaeger | 256Mi | 512Mi | 100m | 500m | 20Gi |
| PostgreSQL | 512Mi | 1Gi | 200m | 1000m | 100Gi |
| Redis | 256Mi | 512Mi | 100m | 500m | 10Gi |

## Resource Calculation Methodology

### Memory Planning Formula
```
Total Memory Needed = (System Overhead + Application Requests + Buffer)

System Overhead = K3s + OS = ~1GB per node
Application Requests = Sum of all app memory requests
Buffer = 20-30% of (System + Apps) for bursts and growth
```

### CPU Planning Formula
```
Total CPU Needed = (System Overhead + Application Requests + Buffer)

System Overhead = K3s + OS = ~0.5 cores per node
Application Requests = Sum of all app CPU requests
Buffer = 50% of (System + Apps) for bursts and scheduling
```

### Example Calculation (Current State)
```
Memory per Node:
- K3s System: 512Mi
- OS Overhead: 256Mi
- Applications: 1024Mi (average)
- Buffer (30%): 537Mi
- Total Needed: ~2.3GB per node

CPU per Node:
- K3s System: 0.3 cores
- OS Overhead: 0.1 cores
- Applications: 0.5 cores (average)
- Buffer (50%): 0.45 cores
- Total Needed: ~1.35 cores per node
```

## Storage Planning

### Current Storage Allocation
- **System Storage**: 25GB per VM (adequate)
- **Application Storage**: Using local-path provisioner
- **Backup Storage**: Not configured

### Recommended Storage Strategy

#### 1. Separate Storage Classes
```yaml
# Local storage for temporary data
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path-fast
provisioner: rancher.io/local-path
parameters:
  nodePath: /opt/local-path-provisioner
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer

# Network storage for persistent data (future)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.local
  share: /mnt/k8s-storage
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

#### 2. Storage Requirements by Application
| Application | Storage Type | Size | Backup Required |
|-------------|--------------|------|-----------------|
| ArgoCD | local-path | 5Gi | Yes |
| Grafana | local-path | 10Gi | Yes |
| N8N | local-path | 20Gi | Yes |
| Lidarr | nfs-storage | 100Gi | No (media cache) |
| Prometheus | local-path | 100Gi | No (metrics) |
| PostgreSQL | local-path | 50Gi | Yes |

## Implementation Strategy

### Step 1: Update Terraform Configuration
```hcl
# terraform/variables.tf
variable "vm_memory" {
  type    = number
  default = 4096
  validation {
    condition     = var.vm_memory >= 4096
    error_message = "VM memory must be at least 4GB for K8s workloads."
  }
}

variable "vm_cores" {
  type    = number
  default = 2
  validation {
    condition     = var.vm_cores >= 2
    error_message = "VM cores must be at least 2 for K8s workloads."
  }
}

# Add storage configuration
variable "vm_storage_size" {
  type    = string
  default = "50G"  # Increase from 25G
}
```

### Step 2: Update Terraform Main Configuration
```hcl
# terraform/main.tf - Update disk configuration
disks {
  scsi {
    scsi0 {
      disk {
        storage = var.vm_storage
        size    = var.vm_storage_size  # Use variable instead of hardcoded
      }
    }
  }
}
```

### Step 3: Apply Resource Limits to All Applications
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

### Step 4: Monitor Resource Usage
```bash
# Install metrics-server if not present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Monitor resource usage
watch kubectl top nodes
watch kubectl top pods -A
```

## Cost-Benefit Analysis

### Current Setup Costs
- **Underutilized Resources**: Paying for 10GB RAM, using ~3GB effectively
- **Performance Issues**: Applications failing due to resource constraints
- **Operational Overhead**: Time spent troubleshooting resource issues

### Improved Setup Benefits
- **Better Resource Utilization**: 80-90% effective usage
- **Improved Reliability**: Applications have adequate resources
- **Future Growth**: Room for additional applications
- **Better Performance**: Faster response times and processing

### Resource Cost Comparison
| Metric | Current | Phase 1 | Phase 2 | Phase 3 |
|--------|---------|---------|---------|---------|
| Total RAM | 10GB | 20GB | 30GB | 40GB |
| Total CPU | 5 cores | 10 cores | 15 cores | 20 cores |
| Effective Usage | ~30% | ~80% | ~75% | ~70% |
| App Capacity | 3-5 apps | 8-12 apps | 15-20 apps | 25-30 apps |

## Monitoring and Alerting

### Resource Monitoring Setup
```yaml
# Prometheus alert for high memory usage
- alert: HighMemoryUsage
  expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.85
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High memory usage on {{ $labels.instance }}"

# Prometheus alert for high CPU usage
- alert: HighCPUUsage
  expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage on {{ $labels.instance }}"
```

### Capacity Planning Dashboard
Create Grafana dashboard with:
- Node resource utilization over time
- Pod resource requests vs usage
- Storage utilization trends
- Application performance metrics

This resource planning guide should help you optimize your infrastructure for better performance and reliability while planning for future growth.
