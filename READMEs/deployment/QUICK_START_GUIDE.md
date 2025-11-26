# Quick Start Implementation Guide

## Priority Actions (This Week)

### 1. Immediate Resource Fix (Day 1-2)
The most critical issue is resource allocation. Your 2GB RAM per VM is insufficient for K8s workloads.

```bash
# Update Terraform variables
cd /mnt/secondary_ssd/Code/homelab/infra/terraform

# Edit variables.tf
vim variables.tf
# Change vm_memory from 2048 to 4096
# Change vm_cores from 1 to 2

# Apply changes
terraform plan
terraform apply
```

### 2. Fix Application Resource Specifications (Day 2-3)
Add resource requests/limits to prevent scheduling issues:

```bash
# Update each application's values.yaml
cd /mnt/secondary_ssd/Code/homelab/infra/k8s

# For each app directory (grafana, n8n, etc.), add:
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### 3. Simplify Network Architecture (Day 3-4)
Remove nginx-proxy-manager from the chain:

```bash
# Update Cloudflare tunnel to point directly to Traefik
# Update tunnel config to: service: http://192.168.50.15:80

# Apply updated Traefik configuration with Cloudflare IPs
kubectl apply -f k8s/traefik/traefik-override.yml
```

## Critical Issues Identified

### 1. Resource Starvation
**Problem**: Applications failing to start due to insufficient resources
**Impact**: Only 3 out of 6+ applications working
**Solution**: Double VM resources immediately

### 2. Network Complexity
**Problem**: Too many proxy layers causing DNS/SSL issues
**Impact**: Difficult hostname resolution, SSL conflicts
**Solution**: Direct Cloudflare → Traefik routing

### 3. Missing Resource Specifications
**Problem**: Kubernetes can't schedule workloads efficiently
**Impact**: Poor resource utilization, random failures
**Solution**: Add resource requests/limits to all apps

### 4. Inconsistent Helm Charts
**Problem**: Mixed deployment patterns, missing templates
**Impact**: Difficult maintenance, unreliable deployments
**Solution**: Standardize chart structure

## Implementation Checklist

### Week 1: Foundation Fixes
- [ ] **Day 1**: Update Terraform VM resources (4GB RAM, 2 CPU cores)
- [ ] **Day 1**: Recreate VMs with new resources
- [ ] **Day 2**: Add resource specifications to all applications
- [ ] **Day 2**: Test application deployments
- [ ] **Day 3**: Update Cloudflare tunnel configuration
- [ ] **Day 3**: Remove nginx-proxy-manager from chain
- [ ] **Day 4**: Update Traefik with Cloudflare IP trust
- [ ] **Day 4**: Test external access to all applications
- [ ] **Day 5**: Verify SSL certificates are working
- [ ] **Weekend**: Monitor resource usage and application health

### Week 2: Standardization
- [ ] **Day 1-2**: Standardize Helm chart structure
- [ ] **Day 3-4**: Update all applications to use standard templates
- [ ] **Day 5**: Implement health checks for all applications
- [ ] **Weekend**: Test ArgoCD sync and application reliability

### Week 3: Monitoring & Optimization
- [ ] **Day 1-2**: Set up resource monitoring
- [ ] **Day 3-4**: Optimize resource allocation based on actual usage
- [ ] **Day 5**: Document operational procedures
- [ ] **Weekend**: Plan for additional applications

## Expected Outcomes

### After Week 1
- All applications should be running and accessible
- External DNS resolution should work consistently
- SSL certificates should be automatically provisioned
- Resource utilization should be visible and appropriate

### After Week 2
- Consistent deployment patterns across all applications
- Reliable ArgoCD synchronization
- Standardized monitoring and health checks
- Easier troubleshooting and maintenance

### After Week 3
- Comprehensive monitoring and alerting
- Optimized resource allocation
- Clear operational procedures
- Ready for additional application deployments

## Troubleshooting Quick Reference

### Application Won't Start
```bash
# Check resource availability
kubectl top nodes

# Check pod status
kubectl get pods -A

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check resource requests
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Requests:"
```

### DNS Not Resolving
```bash
# Test external DNS
dig grafana.theblacklodge.dev

# Test from inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup grafana.theblacklodge.dev

# Check ingress
kubectl get ingress -A
```

### SSL Certificate Issues
```bash
# Check certificate status
kubectl get certificates -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Test certificate
openssl s_client -connect grafana.theblacklodge.dev:443
```

### High Resource Usage
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check for resource limits
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## Success Metrics

### Technical Metrics
- **Application Availability**: 95%+ uptime for all applications
- **Resource Utilization**: 60-80% memory, 40-60% CPU usage
- **Response Time**: < 2 seconds for web applications
- **Certificate Renewal**: Automatic, no manual intervention

### Operational Metrics
- **Deployment Time**: < 5 minutes for new applications
- **Troubleshooting Time**: < 15 minutes for common issues
- **Recovery Time**: < 10 minutes for application restarts
- **Maintenance Overhead**: < 2 hours per week

## Next Steps After Quick Start

### Month 2: Advanced Features
- Implement backup strategies
- Add monitoring and alerting
- Set up log aggregation
- Implement security policies

### Month 3: Scaling
- Add more applications
- Implement auto-scaling
- Optimize storage solutions
- Plan for high availability

### Month 4+: Production Readiness
- Implement disaster recovery
- Add comprehensive monitoring
- Optimize performance
- Document all procedures

This quick start guide focuses on the most critical issues first. The resource allocation problem is your biggest blocker - fix that first, and many other issues will resolve themselves.
