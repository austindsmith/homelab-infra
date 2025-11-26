# Kubernetes Development Workflow Guide

## Development Philosophy

### Think GitOps First
- **Source of Truth**: Git repository contains desired state
- **Declarative**: Define what you want, not how to get there
- **Automated**: Changes trigger automatic deployments
- **Observable**: Monitor and validate deployments

### Application Lifecycle Mindset
1. **Development**: Local testing and validation
2. **Staging**: Integration testing in cluster
3. **Production**: Automated deployment via GitOps
4. **Monitoring**: Continuous health and performance monitoring

## Kubernetes Development Workflow

### 1. Local Development Setup

#### Prerequisites
```bash
# Install required tools
# kubectl - Kubernetes CLI
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# helm - Package manager
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k9s - Terminal UI (optional but recommended)
curl -sS https://webinstall.dev/k9s | bash

# kubectx/kubens - Context switching (optional)
sudo apt install kubectx
```

#### Development Environment
```bash
# Set up development namespace
kubectl create namespace dev

# Set default namespace for development
kubens dev

# Create development context
kubectl config set-context dev --cluster=default --user=default --namespace=dev
kubectl config use-context dev
```

### 2. Application Development Pattern

#### Standard Application Structure
```
k8s/[app-name]/
├── Chart.yaml              # Helm chart metadata
├── values.yaml             # Default values
├── values-dev.yaml         # Development overrides
├── values-prod.yaml        # Production overrides
├── templates/
│   ├── deployment.yaml     # Main application
│   ├── service.yaml        # Service definition
│   ├── ingress.yaml        # External access
│   ├── configmap.yaml      # Configuration
│   ├── secret.yaml         # Sensitive data
│   ├── pvc.yaml           # Storage (if needed)
│   ├── serviceaccount.yaml # RBAC (if needed)
│   └── _helpers.tpl       # Template helpers
└── README.md              # Application documentation
```

#### Development Workflow Steps

##### Step 1: Create Application Structure
```bash
# Create new application
cd /mnt/secondary_ssd/Code/homelab/infra/k8s
mkdir -p myapp/templates

# Copy from template or create from scratch
cp -r _templates/* myapp/
```

##### Step 2: Define Application Values
```yaml
# k8s/myapp/values.yaml
replicaCount: 1

image:
  repository: myapp
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: true
  className: "traefik"
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - host: myapp.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.theblacklodge.dev

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

persistence:
  enabled: false
  storageClass: "local-path"
  size: 8Gi

env:
  NODE_ENV: production
  LOG_LEVEL: info

configMap:
  enabled: false
  data: {}

secret:
  enabled: false
  data: {}
```

##### Step 3: Create Kubernetes Templates
```yaml
# k8s/myapp/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "myapp.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          {{- if .Values.healthCheck.enabled }}
          livenessProbe:
            {{- toYaml .Values.healthCheck.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.healthCheck.readinessProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if or .Values.env .Values.configMap.enabled .Values.secret.enabled }}
          env:
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
            {{- if .Values.configMap.enabled }}
            - name: CONFIG_MAP_REF
              valueFrom:
                configMapKeyRef:
                  name: {{ include "myapp.fullname" . }}
                  key: config
            {{- end }}
            {{- if .Values.secret.enabled }}
            - name: SECRET_REF
              valueFrom:
                secretKeyRef:
                  name: {{ include "myapp.fullname" . }}
                  key: secret
            {{- end }}
          {{- end }}
          {{- if .Values.persistence.enabled }}
          volumeMounts:
            - name: data
              mountPath: /data
          {{- end }}
      {{- if .Values.persistence.enabled }}
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ include "myapp.fullname" . }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

##### Step 4: Local Testing and Validation
```bash
# Validate Helm chart syntax
helm lint k8s/myapp/

# Test template rendering
helm template myapp k8s/myapp/ --values k8s/myapp/values-dev.yaml

# Dry run deployment
helm install myapp k8s/myapp/ --dry-run --debug

# Deploy to development namespace
helm install myapp k8s/myapp/ --namespace dev --create-namespace

# Test the deployment
kubectl get pods -n dev
kubectl logs -f deployment/myapp -n dev
```

##### Step 5: Iterative Development
```bash
# Make changes to templates or values
vim k8s/myapp/values.yaml

# Update deployment
helm upgrade myapp k8s/myapp/ --namespace dev

# Test changes
kubectl get pods -n dev
kubectl describe pod myapp-xxx -n dev

# Debug issues
kubectl logs myapp-xxx -n dev
kubectl exec -it myapp-xxx -n dev -- /bin/sh
```

### 3. GitOps Integration with ArgoCD

#### Create ArgoCD Application
```yaml
# argocd/applications/myapp.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/austindsmith/homelab-infra
    targetRevision: main
    path: k8s/myapp
    helm:
      valueFiles:
        - values.yaml
        # - values-prod.yaml  # Uncomment for production
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
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
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore replica count for HPA
```

#### GitOps Workflow
```bash
# 1. Develop locally
helm install myapp k8s/myapp/ --namespace dev

# 2. Test and validate
kubectl get pods -n dev
curl https://myapp-dev.theblacklodge.dev

# 3. Commit changes
git add k8s/myapp/
git commit -m "feat: add myapp application"
git push origin main

# 4. Deploy via ArgoCD
kubectl apply -f argocd/applications/myapp.yaml

# 5. Monitor deployment
kubectl get applications -n argocd
argocd app get myapp
argocd app sync myapp
```

### 4. Environment Management

#### Development Environment
```yaml
# k8s/myapp/values-dev.yaml
replicaCount: 1

image:
  tag: "dev"

ingress:
  hosts:
    - host: myapp-dev.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-dev-tls
      hosts:
        - myapp-dev.theblacklodge.dev

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

env:
  NODE_ENV: development
  LOG_LEVEL: debug
  DEBUG: "true"
```

#### Production Environment
```yaml
# k8s/myapp/values-prod.yaml
replicaCount: 3

image:
  tag: "v1.0.0"

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

persistence:
  enabled: true
  size: 20Gi

env:
  NODE_ENV: production
  LOG_LEVEL: warn
```

### 5. Testing and Validation Strategies

#### Unit Testing (Helm Charts)
```bash
# Install helm unittest plugin
helm plugin install https://github.com/quintush/helm-unittest

# Create test files
mkdir -p k8s/myapp/tests

# k8s/myapp/tests/deployment_test.yaml
suite: test deployment
templates:
  - deployment.yaml
tests:
  - it: should create deployment
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: myapp

  - it: should set correct image
    set:
      image.repository: myapp
      image.tag: v1.0.0
    asserts:
      - equal:
          path: spec.template.spec.containers[0].image
          value: myapp:v1.0.0

# Run tests
helm unittest k8s/myapp/
```

#### Integration Testing
```bash
# Create test script
cat > test-myapp.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing myapp deployment..."

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/myapp -n myapp

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://myapp.myapp.svc.cluster.local

# Test ingress
curl -f https://myapp.theblacklodge.dev

echo "All tests passed!"
EOF

chmod +x test-myapp.sh
./test-myapp.sh
```

#### Health Check Validation
```yaml
# Add comprehensive health checks
healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /health
      port: http
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  readinessProbe:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 3
    failureThreshold: 3
  startupProbe:
    httpGet:
      path: /startup
      port: http
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 30
```

### 6. Debugging and Troubleshooting

#### Common Debugging Commands
```bash
# Check pod status
kubectl get pods -n myapp

# Describe pod for events
kubectl describe pod myapp-xxx -n myapp

# Check logs
kubectl logs -f deployment/myapp -n myapp

# Check previous container logs
kubectl logs myapp-xxx -n myapp --previous

# Execute into container
kubectl exec -it myapp-xxx -n myapp -- /bin/sh

# Port forward for local testing
kubectl port-forward svc/myapp 8080:80 -n myapp

# Check resource usage
kubectl top pods -n myapp
kubectl top nodes
```

#### ArgoCD Debugging
```bash
# Check application status
kubectl get applications -n argocd

# Describe application
kubectl describe application myapp -n argocd

# Check ArgoCD logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Manual sync
argocd app sync myapp

# Check diff
argocd app diff myapp
```

#### Network Debugging
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup myapp.myapp.svc.cluster.local

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://myapp.myapp.svc.cluster.local

# Check ingress
kubectl get ingress -n myapp
kubectl describe ingress myapp -n myapp

# Test external access
curl -I https://myapp.theblacklodge.dev
```

### 7. Performance and Scaling

#### Resource Management
```yaml
# Set appropriate resource requests and limits
resources:
  requests:
    cpu: 100m      # Minimum CPU needed
    memory: 128Mi  # Minimum memory needed
  limits:
    cpu: 500m      # Maximum CPU allowed
    memory: 512Mi  # Maximum memory allowed
```

#### Horizontal Pod Autoscaling
```yaml
# Enable HPA in values.yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

#### Vertical Pod Autoscaling (Optional)
```yaml
# VPA for automatic resource adjustment
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"
```

### 8. Security Best Practices

#### Pod Security Context
```yaml
# Add security context to values.yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

#### Network Policies
```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: traefik-system
    ports:
    - protocol: TCP
      port: {{ .Values.service.targetPort }}
  egress:
  - {} # Allow all egress (customize as needed)
{{- end }}
```

This comprehensive guide provides a solid foundation for developing, testing, and deploying Kubernetes applications in your homelab environment. Focus on the GitOps workflow and proper testing to ensure reliable deployments.
