# Complete K3s Cluster Rebuild Guide

## Overview
This guide will walk you through completely tearing down and rebuilding your K3s cluster with best practices, from Terraform VM creation to accessing applications in your browser.

## Prerequisites Checklist
- [ ] Proxmox server accessible
- [ ] Terraform installed and configured
- [ ] Ansible installed and configured
- [ ] kubectl installed
- [ ] Cloudflare API token with DNS permissions
- [ ] SSH key pair generated (`~/.ssh/id_ed25519`)

## Phase 1: Complete Teardown

### Step 1: Backup Important Data
```bash
# Backup current kubeconfig
cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d)

# Backup any persistent data you want to keep
# (Note: This rebuild will lose all data)

# Export current ArgoCD applications (optional)
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml
```

### Step 2: Destroy Existing Infrastructure
```bash
cd /mnt/secondary_ssd/Code/homelab/infra/terraform

# Destroy all VMs
terraform destroy -auto-approve

# Verify VMs are gone in Proxmox UI
```

## Phase 2: Infrastructure Preparation

### Step 3: Update Terraform Configuration
```bash
cd /mnt/secondary_ssd/Code/homelab/infra/terraform

# Update variables.tf with improved settings
```

Create the updated configuration:

```hcl
# terraform/variables.tf (Updated)
variable "ssh_pubkey_path" {
  type    = string
  default = "/home/austin/.ssh/id_ed25519.pub"
}

variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type = string
  sensitive = true
}

variable "node_name" {
  type    = string
  default = "proxmox"
}

variable "vm_template" {
  type    = string
  default = "ubuntu-2004-cloudinit-template"
}

variable "vm_storage" {
  type    = string
  default = "local-lvm"
}

variable "vm_password" {
  type      = string
  sensitive = true
}

# UPDATED: Increased resources
variable "vm_memory" {
  type    = number
  default = 4096  # Increased from 2048
  validation {
    condition     = var.vm_memory >= 4096
    error_message = "VM memory must be at least 4GB for K8s workloads."
  }
}

variable "vm_cores" {
  type    = number
  default = 2     # Increased from 1
  validation {
    condition     = var.vm_cores >= 2
    error_message = "VM cores must be at least 2 for K8s workloads."
  }
}

variable "vm_count" {
  type    = number
  default = 5
}

# NEW: Storage size variable
variable "vm_storage_size" {
  type    = string
  default = "50G"  # Increased from 25G
}
```

Update main.tf:
```hcl
# terraform/main.tf (Key updates)
resource "proxmox_vm_qemu" "k3s_vm" {
  count = var.vm_count
  name        = "lab-k8s-${count.index + 1}"
  vmid        = 2000 + count.index

  target_node = var.node_name
  clone      = var.vm_template
  full_clone = true
  
  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  agent  = 1
  os_type = "cloud-init"
  memory = var.vm_memory
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.vm_storage
          size    = var.vm_storage_size  # Use variable
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.vm_storage
        }
      }
    }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    id     = 0
    tag    = 2
    macaddr = format(
      "02:%s:%s:%s:%s:%s",
      substr(random_id.mac[count.index].hex, 0, 2),
      substr(random_id.mac[count.index].hex, 2, 2),
      substr(random_id.mac[count.index].hex, 4, 2),
      substr(random_id.mac[count.index].hex, 6, 2),
      substr(random_id.mac[count.index].hex, 8, 2)
    )
  }

  lifecycle {
    ignore_changes = [
      network,
      disks
    ]
  }

  ipconfig0 = "ip=192.168.50.${15 + count.index}/24,gw=192.168.50.1"
  vm_state = "running"
  nameserver = "1.1.1.1 8.8.8.8"

  ciuser  = "root"
  cipassword = var.vm_password
  sshkeys = file(var.ssh_pubkey_path)
  onboot = true
}
```

### Step 4: Create VMs with New Configuration
```bash
# Initialize and apply Terraform
terraform init
terraform plan
terraform apply

# Wait for VMs to be ready (about 5 minutes)
# Test SSH connectivity to all nodes
for i in {15..19}; do
  echo "Testing SSH to 192.168.50.$i"
  ssh -o ConnectTimeout=5 root@192.168.50.$i "echo 'Node $i ready'"
done
```

## Phase 3: Ansible Configuration Improvements

### Step 5: Update Ansible Configuration
```bash
cd /mnt/secondary_ssd/Code/homelab/infra/ansible
```

Create improved Ansible configuration:

```ini
# ansible/ansible.cfg (Updated)
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = memory
stdout_callback = yaml
bin_ansible_callbacks = True

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
```

```yaml
# ansible/group_vars/all.yml (New file)
---
# Global variables for all hosts
ansible_user: root
ansible_ssh_private_key_file: ~/.ssh/id_ed25519
ansible_port: 22
ansible_become: false

# K3s configuration
k3s_version: v1.28.5+k3s1
k3s_token: "{{ vault_k3s_token | default('my-super-secret-token') }}"
k3s_server_location: /var/lib/rancher/k3s
k3s_kubeconfig_mode: "0644"

# Network configuration
k3s_cluster_cidr: "10.42.0.0/16"
k3s_service_cidr: "10.43.0.0/16"
k3s_cluster_dns: "10.43.0.10"

# Feature gates and configuration
k3s_server_args: >-
  --snapshotter=native
  --disable=traefik
  --disable=servicelb
  --cluster-cidr={{ k3s_cluster_cidr }}
  --service-cidr={{ k3s_service_cidr }}
  --cluster-dns={{ k3s_cluster_dns }}
  --write-kubeconfig-mode={{ k3s_kubeconfig_mode }}

k3s_agent_args: >-
  --snapshotter=native
```

```yaml
# ansible/group_vars/k3s_servers.yml (Updated)
---
# Server-specific configuration
k3s_control_node: true
k3s_server: true

# First server gets different args (no join)
k3s_server_init_args: >-
  {{ k3s_server_args }}
  --cluster-init

# Additional servers join the cluster
k3s_server_join_args: >-
  {{ k3s_server_args }}
  --server https://{{ hostvars[groups['k3s_servers'][0]]['ansible_host'] }}:6443
```

### Step 6: Create Improved Ansible Playbooks

```yaml
# ansible/playbooks/00-system-prep.yml (New file)
---
- name: Prepare system for K3s
  hosts: k3s
  become: true
  tasks:
    - name: Update system packages
      apt:
        update_cache: yes
        upgrade: dist
        autoremove: yes
        autoclean: yes

    - name: Install required packages
      apt:
        name:
          - curl
          - wget
          - git
          - htop
          - iotop
          - nfs-common
          - open-iscsi
        state: present

    - name: Disable swap
      shell: |
        swapoff -a
        sed -i '/swap/d' /etc/fstab

    - name: Enable IP forwarding
      sysctl:
        name: net.ipv4.ip_forward
        value: '1'
        state: present
        reload: yes

    - name: Disable firewall (for lab environment)
      systemd:
        name: ufw
        state: stopped
        enabled: no
      ignore_errors: yes

    - name: Set timezone
      timezone:
        name: America/New_York  # Adjust as needed

    - name: Reboot if needed
      reboot:
        reboot_timeout: 300
      when: ansible_facts['reboot_required'] | default(false)
```

```yaml
# ansible/playbooks/01-install-k3s.yml (Improved)
---
- name: Install K3s servers
  hosts: k3s_servers
  become: true
  serial: 1
  tasks:
    - name: Check if K3s is already installed
      stat:
        path: /usr/local/bin/k3s
      register: k3s_binary

    - name: Download K3s installation script
      get_url:
        url: https://get.k3s.io
        dest: /tmp/k3s-install.sh
        mode: '0755'
      when: not k3s_binary.stat.exists

    - name: Install first K3s server (cluster init)
      shell: |
        INSTALL_K3S_VERSION={{ k3s_version }} \
        K3S_TOKEN={{ k3s_token }} \
        /tmp/k3s-install.sh server {{ k3s_server_init_args }}
      when: 
        - not k3s_binary.stat.exists
        - inventory_hostname == groups['k3s_servers'][0]

    - name: Wait for first server to be ready
      wait_for:
        port: 6443
        host: "{{ ansible_host }}"
        timeout: 300
      when: inventory_hostname == groups['k3s_servers'][0]

    - name: Install additional K3s servers
      shell: |
        INSTALL_K3S_VERSION={{ k3s_version }} \
        K3S_TOKEN={{ k3s_token }} \
        /tmp/k3s-install.sh server {{ k3s_server_join_args }}
      when: 
        - not k3s_binary.stat.exists
        - inventory_hostname != groups['k3s_servers'][0]

    - name: Wait for server API to be ready
      uri:
        url: "https://{{ ansible_host }}:6443/readyz"
        validate_certs: no
      register: api_ready
      retries: 30
      delay: 10
      until: api_ready.status == 200

- name: Install K3s agents
  hosts: k3s_agents
  become: true
  vars:
    primary_server: "{{ groups['k3s_servers'][0] }}"
  tasks:
    - name: Check if K3s is already installed
      stat:
        path: /usr/local/bin/k3s
      register: k3s_binary

    - name: Download K3s installation script
      get_url:
        url: https://get.k3s.io
        dest: /tmp/k3s-install.sh
        mode: '0755'
      when: not k3s_binary.stat.exists

    - name: Wait for server to be available
      wait_for:
        host: "{{ hostvars[primary_server].ansible_host }}"
        port: 6443
        timeout: 300

    - name: Install K3s agent
      shell: |
        INSTALL_K3S_VERSION={{ k3s_version }} \
        K3S_URL=https://{{ hostvars[primary_server].ansible_host }}:6443 \
        K3S_TOKEN={{ k3s_token }} \
        /tmp/k3s-install.sh agent {{ k3s_agent_args }}
      when: not k3s_binary.stat.exists

- name: Verify cluster
  hosts: k3s_servers[0]
  become: true
  tasks:
    - name: Get cluster status
      shell: kubectl get nodes
      register: cluster_status

    - name: Display cluster status
      debug:
        var: cluster_status.stdout_lines
```

```yaml
# ansible/playbooks/02-setup-kubeconfig.yml (New file)
---
- name: Setup kubeconfig
  hosts: k3s_servers[0]
  become: true
  tasks:
    - name: Get kubeconfig content
      slurp:
        src: /etc/rancher/k3s/k3s.yaml
      register: kubeconfig_content

    - name: Create local .kube directory
      file:
        path: "{{ ansible_env.HOME }}/.kube"
        state: directory
        mode: '0755'
      delegate_to: localhost
      become: false

    - name: Write kubeconfig to local machine
      copy:
        content: "{{ kubeconfig_content.content | b64decode | regex_replace('127.0.0.1', ansible_host) }}"
        dest: "{{ ansible_env.HOME }}/.kube/config"
        mode: '0600'
      delegate_to: localhost
      become: false

    - name: Test kubectl connectivity
      shell: kubectl get nodes
      delegate_to: localhost
      become: false
      register: kubectl_test

    - name: Display kubectl test results
      debug:
        var: kubectl_test.stdout_lines
```

### Step 7: Update Site Playbook
```yaml
# ansible/site.yml (Updated)
---
- import_playbook: playbooks/00-system-prep.yml
- import_playbook: playbooks/01-install-k3s.yml
- import_playbook: playbooks/02-setup-kubeconfig.yml
```

### Step 8: Run Ansible Deployment
```bash
cd /mnt/secondary_ssd/Code/homelab/infra/ansible

# Test connectivity
ansible all -m ping

# Run the complete deployment
ansible-playbook site.yml

# Verify cluster is working
kubectl get nodes
kubectl get pods -A
```

## Phase 4: Kubernetes Application Setup

### Step 9: Install Core Components

```bash
# Install Traefik with proper configuration
kubectl apply -f - <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  repo: https://traefik.github.io/charts
  chart: traefik
  targetNamespace: kube-system
  version: 25.0.0
  set:
    ports.web.redirectTo: websecure
    ports.websecure.tls.enabled: "true"
    service.type: LoadBalancer
    service.spec.externalIPs[0]: "192.168.50.15"
    logs.general.level: INFO
    logs.access.enabled: "true"
    metrics.prometheus.enabled: "true"
  valuesContent: |
    additionalArguments:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--providers.kubernetesingress.ingressendpoint.ip=192.168.50.15"
      - "--entrypoints.websecure.http.tls.options=default@kubernetescrd"
    
    ports:
      websecure:
        forwardedHeaders:
          trustedIPs:
            - 173.245.48.0/20
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
EOF

# Wait for Traefik to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=300s
```

### Step 10: Install cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Create Cloudflare API token secret
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN \
  -n cert-manager

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@domain.com
    privateKeySecretRef:
      name: letsencrypt-dns-private-key
    solvers:
    - dns01:
        cloudflare:
          email: your-cloudflare-email@domain.com
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
      selector:
        dnsZones:
        - "theblacklodge.dev"
EOF
```

### Step 11: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

# Create ArgoCD ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
    traefik.ingress.kubernetes.io/router.tls: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - argo.theblacklodge.dev
      secretName: argocd-server-tls
  rules:
    - host: argo.theblacklodge.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
EOF

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Phase 5: Application Deployment

### Step 12: Create Standardized Application Structure

```bash
cd /mnt/secondary_ssd/Code/homelab/infra/k8s

# Create homepage application
mkdir -p homepage/templates
```

Create standardized homepage chart:

```yaml
# k8s/homepage/Chart.yaml
apiVersion: v2
name: homepage
description: A Helm chart for Homepage dashboard
type: application
version: 0.1.0
appVersion: "latest"
```

```yaml
# k8s/homepage/values.yaml
replicaCount: 1

image:
  repository: ghcr.io/gethomepage/homepage
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

ingress:
  enabled: true
  className: "traefik"
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
    traefik.ingress.kubernetes.io/router.tls: "true"
  hosts:
    - host: homepage.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: homepage-tls
      hosts:
        - homepage.theblacklodge.dev

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

persistence:
  enabled: true
  storageClass: "local-path"
  accessMode: ReadWriteOnce
  size: 1Gi

healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 5
```

### Step 13: Deploy Applications via ArgoCD

```bash
# Create ArgoCD application for homepage
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homepage
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/austindsmith/homelab-infra
    targetRevision: main
    path: k8s/homepage
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: homepage
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
```

## Phase 6: Validation and Testing

### Step 14: Comprehensive Testing

```bash
# Test cluster health
kubectl get nodes
kubectl get pods -A
kubectl top nodes
kubectl top pods -A

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default.svc.cluster.local

# Test external DNS
dig homepage.theblacklodge.dev

# Test certificate generation
kubectl get certificates -A

# Test ingress
kubectl get ingress -A

# Test application accessibility
curl -I https://homepage.theblacklodge.dev
curl -I https://argo.theblacklodge.dev
```

### Step 15: Configure Cloudflare Tunnel

```bash
# Update your Cloudflare tunnel configuration to point directly to Traefik
# Remove nginx-proxy-manager from the chain

# Example tunnel config:
# ingress:
#   - hostname: "*.theblacklodge.dev"
#     service: http://192.168.50.15:80
#     originRequest:
#       httpHostHeader: "*.theblacklodge.dev"
#       noTLSVerify: true
#   - service: http_status:404
```

### Step 16: Final Validation

```bash
# Test complete flow: Browser → Cloudflare → Traefik → App
echo "Testing complete application flow..."

# Test homepage
echo "1. Testing Homepage..."
curl -L https://homepage.theblacklodge.dev

# Test ArgoCD
echo "2. Testing ArgoCD..."
curl -L https://argo.theblacklodge.dev

# Check resource utilization
echo "3. Checking resource utilization..."
kubectl top nodes
kubectl top pods -A

echo "Rebuild complete! 🎉"
echo "Access your applications:"
echo "- Homepage: https://homepage.theblacklodge.dev"
echo "- ArgoCD: https://argo.theblacklodge.dev"
echo "- ArgoCD Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
```

## Success Criteria

After completing this guide, you should have:
- [ ] 5 VMs with 4GB RAM and 2 CPU cores each
- [ ] Functional K3s cluster with all nodes ready
- [ ] Traefik ingress controller with Cloudflare integration
- [ ] cert-manager with automatic SSL certificate generation
- [ ] ArgoCD for GitOps deployments
- [ ] At least one application (Homepage) accessible via browser
- [ ] Proper resource utilization (60-80% memory, 40-60% CPU)
- [ ] All applications showing healthy status in ArgoCD

## Next Steps

1. **Add More Applications**: Use the standardized chart structure for additional apps
2. **Implement Monitoring**: Deploy Prometheus and Grafana
3. **Set Up Backups**: Configure backup strategies for persistent data
4. **Security Hardening**: Implement RBAC and security policies
5. **Documentation**: Document your specific configurations and procedures

This rebuild should give you a solid, scalable foundation for your homelab infrastructure!
