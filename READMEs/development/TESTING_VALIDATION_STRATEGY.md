# Testing and Validation Strategy

## Testing Philosophy

### Multi-Layer Testing Approach
1. **Infrastructure Layer**: Terraform and Ansible validation
2. **Platform Layer**: Kubernetes cluster health and functionality
3. **Application Layer**: Individual application testing
4. **Integration Layer**: End-to-end workflow validation
5. **Performance Layer**: Resource usage and scaling validation

### Testing Pyramid for Infrastructure
```
    /\
   /  \     E2E Tests (Few, Expensive)
  /____\
 /      \   Integration Tests (Some, Moderate)
/________\  Unit Tests (Many, Fast)
```

## Infrastructure Testing

### 1. Terraform Validation

#### Static Analysis
```bash
# Terraform validation script
#!/bin/bash
# scripts/validate-terraform.sh

set -e

echo "🔍 Validating Terraform configuration..."

cd terraform/

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check -recursive

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Security scanning with tfsec
if command -v tfsec &> /dev/null; then
    echo "Running security scan..."
    tfsec .
fi

# Plan validation
echo "Creating Terraform plan..."
terraform plan -out=tfplan

echo "✅ Terraform validation complete"
```

#### Resource Validation
```hcl
# terraform/validation.tf
# Add validation rules to variables

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

variable "vm_count" {
  type    = number
  default = 5
  validation {
    condition     = var.vm_count >= 3 && var.vm_count <= 10
    error_message = "VM count must be between 3 and 10."
  }
}
```

### 2. Ansible Testing

#### Syntax and Lint Testing
```bash
#!/bin/bash
# scripts/validate-ansible.sh

set -e

echo "🔍 Validating Ansible playbooks..."

cd ansible/

# Syntax check
echo "Checking Ansible syntax..."
ansible-playbook --syntax-check site.yml

# Lint check
if command -v ansible-lint &> /dev/null; then
    echo "Running Ansible lint..."
    ansible-lint site.yml
fi

# Inventory validation
echo "Validating inventory..."
ansible-inventory --list > /dev/null

echo "✅ Ansible validation complete"
```

#### Molecule Testing (Advanced)
```yaml
# ansible/molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: ubuntu-20.04
    image: ubuntu:20.04
    pre_build_image: true
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    capabilities:
      - SYS_ADMIN
provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
verifier:
  name: ansible
```

```yaml
# ansible/molecule/default/verify.yml
---
- name: Verify
  hosts: all
  tasks:
    - name: Check if K3s is installed
      stat:
        path: /usr/local/bin/k3s
      register: k3s_binary

    - name: Verify K3s installation
      assert:
        that:
          - k3s_binary.stat.exists
        fail_msg: "K3s binary not found"

    - name: Check K3s service
      systemd:
        name: k3s
      register: k3s_service

    - name: Verify K3s service is running
      assert:
        that:
          - k3s_service.status.ActiveState == "active"
        fail_msg: "K3s service is not active"
```

## Kubernetes Cluster Testing

### 1. Cluster Health Validation

#### Automated Health Check Script
```bash
#!/bin/bash
# scripts/validate-cluster.sh

set -e

echo "🔍 Validating Kubernetes cluster..."

# Check cluster connectivity
echo "Testing cluster connectivity..."
kubectl cluster-info

# Check node status
echo "Checking node status..."
READY_NODES=$(kubectl get nodes --no-headers | grep Ready | wc -l)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)

if [ "$READY_NODES" -ne "$TOTAL_NODES" ]; then
    echo "❌ Not all nodes are ready: $READY_NODES/$TOTAL_NODES"
    kubectl get nodes
    exit 1
fi

echo "✅ All nodes ready: $READY_NODES/$TOTAL_NODES"

# Check system pods
echo "Checking system pods..."
FAILED_PODS=$(kubectl get pods -n kube-system --no-headers | grep -v Running | grep -v Completed | wc -l)

if [ "$FAILED_PODS" -gt 0 ]; then
    echo "❌ Found $FAILED_PODS failed system pods"
    kubectl get pods -n kube-system | grep -v Running | grep -v Completed
    exit 1
fi

echo "✅ All system pods running"

# Check resource usage
echo "Checking resource usage..."
kubectl top nodes

echo "✅ Cluster validation complete"
```

#### Comprehensive Cluster Test
```yaml
# tests/cluster-validation.yaml
apiVersion: v1
kind: Pod
metadata:
  name: cluster-test
  namespace: default
spec:
  restartPolicy: Never
  containers:
  - name: test
    image: busybox
    command:
    - /bin/sh
    - -c
    - |
      echo "Testing DNS resolution..."
      nslookup kubernetes.default.svc.cluster.local
      
      echo "Testing internet connectivity..."
      wget -q --spider https://google.com
      
      echo "Testing cluster DNS..."
      nslookup kube-dns.kube-system.svc.cluster.local
      
      echo "All tests passed!"
```

### 2. Network Testing

#### Network Connectivity Test
```bash
#!/bin/bash
# scripts/test-network.sh

set -e

echo "🔍 Testing network connectivity..."

# Test pod-to-pod communication
kubectl run test-client --image=busybox --rm -it --restart=Never -- /bin/sh -c "
    echo 'Testing pod-to-pod communication...'
    wget -qO- http://kubernetes.default.svc.cluster.local:443 --no-check-certificate
"

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- /bin/sh -c "
    echo 'Testing DNS resolution...'
    nslookup kubernetes.default.svc.cluster.local
    nslookup google.com
"

# Test ingress connectivity
if kubectl get ingress -A | grep -q .; then
    echo "Testing ingress connectivity..."
    INGRESS_HOSTS=$(kubectl get ingress -A -o jsonpath='{.items[*].spec.rules[*].host}')
    for host in $INGRESS_HOSTS; do
        echo "Testing $host..."
        curl -I "https://$host" --connect-timeout 10 || echo "Failed to connect to $host"
    done
fi

echo "✅ Network tests complete"
```

### 3. Storage Testing

#### Persistent Volume Test
```yaml
# tests/storage-test.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: test
    image: busybox
    command:
    - /bin/sh
    - -c
    - |
      echo "Testing storage write..."
      echo "test data" > /data/test.txt
      
      echo "Testing storage read..."
      cat /data/test.txt
      
      echo "Storage test complete!"
      sleep 30
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc
  restartPolicy: Never
```

## Application Testing

### 1. Helm Chart Testing

#### Unit Tests with helm-unittest
```yaml
# k8s/myapp/tests/deployment_test.yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should create deployment with correct name
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: RELEASE-NAME-myapp

  - it: should set resource limits
    asserts:
      - equal:
          path: spec.template.spec.containers[0].resources.limits.memory
          value: 512Mi
      - equal:
          path: spec.template.spec.containers[0].resources.limits.cpu
          value: 500m

  - it: should configure ingress correctly
    template: ingress.yaml
    set:
      ingress.enabled: true
    asserts:
      - isKind:
          of: Ingress
      - equal:
          path: spec.rules[0].host
          value: myapp.theblacklodge.dev
```

#### Integration Tests
```bash
#!/bin/bash
# scripts/test-application.sh

APP_NAME=$1
NAMESPACE=${2:-$APP_NAME}

if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name> [namespace]"
    exit 1
fi

echo "🔍 Testing application: $APP_NAME in namespace: $NAMESPACE"

# Deploy application
echo "Deploying application..."
helm upgrade --install $APP_NAME k8s/$APP_NAME/ --namespace $NAMESPACE --create-namespace --wait

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/$APP_NAME -n $NAMESPACE

# Test pod status
echo "Checking pod status..."
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=$APP_NAME

# Test service connectivity
echo "Testing service connectivity..."
kubectl run test-$APP_NAME --image=busybox --rm -it --restart=Never -- wget -qO- http://$APP_NAME.$NAMESPACE.svc.cluster.local

# Test ingress (if enabled)
INGRESS_HOST=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)
if [ ! -z "$INGRESS_HOST" ]; then
    echo "Testing ingress: $INGRESS_HOST"
    curl -I https://$INGRESS_HOST --connect-timeout 10
fi

echo "✅ Application test complete: $APP_NAME"
```

### 2. End-to-End Testing

#### Complete Workflow Test
```bash
#!/bin/bash
# scripts/e2e-test.sh

set -e

echo "🚀 Starting end-to-end test..."

# 1. Infrastructure validation
echo "Step 1: Validating infrastructure..."
./scripts/validate-terraform.sh
./scripts/validate-ansible.sh

# 2. Cluster validation
echo "Step 2: Validating cluster..."
./scripts/validate-cluster.sh

# 3. Network validation
echo "Step 3: Validating network..."
./scripts/test-network.sh

# 4. Application deployment and testing
echo "Step 4: Testing applications..."
APPS=("homepage" "grafana" "n8n")

for app in "${APPS[@]}"; do
    echo "Testing $app..."
    ./scripts/test-application.sh $app
done

# 5. ArgoCD validation
echo "Step 5: Validating ArgoCD..."
kubectl get applications -n argocd
argocd app list

# 6. Certificate validation
echo "Step 6: Validating certificates..."
kubectl get certificates -A

# 7. Performance validation
echo "Step 7: Checking performance..."
kubectl top nodes
kubectl top pods -A

echo "🎉 End-to-end test complete!"
```

## Performance and Load Testing

### 1. Resource Usage Monitoring
```bash
#!/bin/bash
# scripts/monitor-resources.sh

DURATION=${1:-300}  # Default 5 minutes
INTERVAL=${2:-10}   # Default 10 seconds

echo "Monitoring resources for $DURATION seconds..."

END_TIME=$(($(date +%s) + DURATION))

while [ $(date +%s) -lt $END_TIME ]; do
    echo "=== $(date) ==="
    kubectl top nodes
    echo ""
    kubectl top pods -A --sort-by=memory | head -10
    echo ""
    sleep $INTERVAL
done

echo "Resource monitoring complete"
```

### 2. Load Testing with k6
```javascript
// tests/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },  // Ramp up
    { duration: '5m', target: 10 },  // Stay at 10 users
    { duration: '2m', target: 0 },   // Ramp down
  ],
};

export default function() {
  let response = http.get('https://homepage.theblacklodge.dev');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 2s': (r) => r.timings.duration < 2000,
  });
  
  sleep(1);
}
```

```bash
# Run load test
k6 run tests/load-test.js
```

## Continuous Testing Pipeline

### 1. GitHub Actions Workflow
```yaml
# .github/workflows/test.yml
name: Infrastructure Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      
    - name: Terraform Validate
      run: |
        cd terraform
        terraform init
        terraform validate
        
    - name: Ansible Lint
      run: |
        pip install ansible-lint
        cd ansible
        ansible-lint site.yml
        
    - name: Helm Lint
      run: |
        helm lint k8s/*/
        
  test-charts:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install helm-unittest
      run: helm plugin install https://github.com/quintush/helm-unittest
      
    - name: Run Helm Tests
      run: |
        for chart in k8s/*/; do
          if [ -d "$chart/tests" ]; then
            echo "Testing $chart"
            helm unittest "$chart"
          fi
        done
```

### 2. Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.81.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate

  - repo: https://github.com/ansible/ansible-lint
    rev: v6.17.2
    hooks:
      - id: ansible-lint
```

## Monitoring and Alerting

### 1. Health Check Endpoints
```yaml
# Add to all applications
healthCheck:
  enabled: true
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

### 2. Prometheus Monitoring
```yaml
# monitoring/prometheus-rules.yaml
groups:
- name: infrastructure
  rules:
  - alert: NodeDown
    expr: up{job="kubernetes-nodes"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Node {{ $labels.instance }} is down"

  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod {{ $labels.pod }} is crash looping"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
```

This comprehensive testing strategy ensures your infrastructure is reliable, performant, and maintainable. Start with the basic validation scripts and gradually add more sophisticated testing as your infrastructure grows.
