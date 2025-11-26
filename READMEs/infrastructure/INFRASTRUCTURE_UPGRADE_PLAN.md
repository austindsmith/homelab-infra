# Infrastructure Upgrade Plan

## Current Issues
- **Disk Pressure**: All nodes experiencing disk pressure with 25GB disks
- **Resource Constraints**: Applications failing to schedule due to insufficient resources
- **Pod Failures**: Multiple applications in CrashLoopBackOff/Pending state

## Recommended Upgrade Configuration

### VM Specifications (Per Node)
- **Memory**: 8GB (increased from 6GB)
- **CPU**: 4 cores (unchanged)
- **Disk**: 100GB (increased from 25GB)
- **Storage**: local-lvm (unchanged)

### Total Resource Allocation (3 Nodes)
- **Total Memory**: 24GB
- **Total CPU**: 12 cores  
- **Total Disk**: 300GB (using ~37% of your 800GB available)

## Terraform Changes Made

### Updated Variables (`terraform/variables.tf`)
```hcl
variable "vm_memory" {
  type    = number
  default = 8192  # 8GB RAM per node
}

variable "vm_disk_size" {
  type        = string
  default     = "100G"  # 100GB per node
  description = "Disk size for each VM"
}

variable "vm_disk_storage" {
  type        = string
  default     = "local-lvm"
  description = "Storage pool for VM disks"
}
```

### Updated Main Configuration (`terraform/main.tf`)
- Disk size now uses variable `var.vm_disk_size`
- Storage pool now uses variable `var.vm_disk_storage`
- More flexible configuration for future changes

## Helm Chart Optimizations

### Reduced Resource Requirements
Applications optimized for better resource efficiency:

#### Superset
- Memory: 512Mi request, 1Gi limit (was 1Gi/2Gi)
- CPU: 250m request, 500m limit (was 500m/1000m)

#### Spark
- Workers reduced to 1 (was 2)
- Memory: 512Mi request, 1Gi limit (was 1Gi/2Gi)
- Worker memory: 512m (was 1g)

#### Dremio
- Memory: 512Mi request, 1Gi limit (was 1Gi/2Gi)
- CPU: 250m request, 500m limit (was 500m/1000m)

## Upgrade Process

### Option 1: Automated Upgrade (Recommended)
```bash
cd /mnt/secondary_ssd/Code/homelab/infra
./scripts/upgrade-infrastructure.sh
```

### Option 2: Manual Upgrade
```bash
# 1. Update Terraform
cd terraform
terraform plan
terraform apply

# 2. Reconfigure cluster
cd ../ansible
ansible-playbook site.yml

# 3. Redeploy applications
cd ..
./scripts/deploy-complete-stack.sh
```

## Expected Benefits

### Performance Improvements
- **4x Disk Space**: Eliminates disk pressure issues
- **33% More Memory**: Better application performance
- **Optimized Resources**: More efficient resource utilization

### Reliability Improvements
- **No More Evictions**: Sufficient disk space prevents pod evictions
- **Stable Scheduling**: Applications can schedule reliably
- **Better Monitoring**: Resource widgets will show accurate data

### Future Expandability
- **Room to Grow**: 100GB per node allows for more applications
- **Flexible Configuration**: Easy to adjust resources via Terraform variables
- **Scalable Architecture**: Can easily add more nodes or increase resources

## Resource Planning

### Current Utilization (After Upgrade)
- **Memory**: ~60% utilization expected
- **CPU**: ~30% utilization expected  
- **Disk**: ~40% utilization expected

### Capacity for Growth
- **Additional Applications**: Can deploy 5-10 more medium-sized applications
- **Data Storage**: Plenty of space for logs, databases, and application data
- **Future Scaling**: Can increase to 5 nodes or larger VM sizes as needed

## Monitoring & Maintenance

### Post-Upgrade Checks
1. **Node Status**: `kubectl get nodes`
2. **Pod Health**: `kubectl get pods -A`
3. **Resource Usage**: `kubectl top nodes`
4. **Disk Usage**: Check via Homepage dashboard

### Ongoing Monitoring
- Monitor disk usage via Kubernetes dashboard
- Set up alerts for >80% disk usage
- Regular cleanup of unused images and containers

## Rollback Plan

If issues occur, you can rollback by:
1. Reverting Terraform variables to original values
2. Running `terraform apply` to restore original VM sizes
3. Re-running Ansible to reconfigure cluster

## Cost Considerations

### Storage Usage
- **Before**: 75GB total (3 × 25GB)
- **After**: 300GB total (3 × 100GB)
- **Increase**: 225GB additional usage

### Performance vs Cost
- Significant performance improvement for moderate storage increase
- Prevents downtime and troubleshooting costs
- Enables reliable demo environment for Thanksgiving

## Conclusion

This upgrade provides a solid foundation for your data lakehouse platform with room for growth and reliable performance. The 100GB per node configuration strikes a good balance between resource availability and storage efficiency.
