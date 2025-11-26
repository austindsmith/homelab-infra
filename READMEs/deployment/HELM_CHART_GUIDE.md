# Helm Chart Standardization Guide

## Current Chart Issues

### Problems Identified
1. **Inconsistent Chart Structure**: Some apps use Chart.yaml, others don't
2. **Mixed Deployment Methods**: HelmChart CRDs vs ArgoCD Applications
3. **Resource Specifications Missing**: No requests/limits defined
4. **Incomplete Templates**: Missing standard Kubernetes resources
5. **Values File Inconsistency**: Different naming conventions and structures

## Recommended Chart Structure

### Standard Directory Layout
```
k8s/[app-name]/
├── Chart.yaml                 # Helm chart metadata
├── values.yaml               # Default configuration values
├── values-dev.yaml          # Development overrides (optional)
├── values-prod.yaml         # Production overrides (optional)
└── templates/
    ├── deployment.yaml      # Main application deployment
    ├── service.yaml         # Service definition
    ├── ingress.yaml         # Ingress configuration
    ├── configmap.yaml       # Configuration data
    ├── secret.yaml          # Sensitive data (if needed)
    ├── serviceaccount.yaml  # Service account (if needed)
    ├── pvc.yaml            # Persistent volume claim (if needed)
    └── _helpers.tpl        # Template helpers
```

## Template Examples

### Chart.yaml Template
```yaml
apiVersion: v2
name: {{ .Chart.Name }}
description: A Helm chart for {{ .Chart.Name }}
type: application
version: 0.1.0
appVersion: "latest"
home: https://github.com/austindsmith/homelab-infra
sources:
  - https://github.com/austindsmith/homelab-infra
maintainers:
  - name: Austin Smith
    email: your-email@domain.com
```

### values.yaml Template
```yaml
# Default values for application
replicaCount: 1

image:
  repository: ""
  pullPolicy: IfNotPresent
  tag: ""

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext: {}

service:
  type: ClusterIP
  port: 80
  targetPort: http

ingress:
  enabled: true
  className: "traefik"
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - host: app.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.theblacklodge.dev

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

persistence:
  enabled: false
  storageClass: "local-path"
  accessMode: ReadWriteOnce
  size: 8Gi

env: {}

configMap:
  enabled: false
  data: {}

secret:
  enabled: false
  data: {}

healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /
      port: http
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /
      port: http
    initialDelaySeconds: 5
    periodSeconds: 5
```

### Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "chart.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "chart.serviceAccountName" . }}
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
                  name: {{ include "chart.fullname" . }}
                  key: config
            {{- end }}
            {{- if .Values.secret.enabled }}
            - name: SECRET_REF
              valueFrom:
                secretKeyRef:
                  name: {{ include "chart.fullname" . }}
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
            claimName: {{ include "chart.fullname" . }}
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

### _helpers.tpl Template
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## Application-Specific Configurations

### Grafana Chart Update
```yaml
# k8s/grafana/values.yaml
image:
  repository: grafana/grafana
  tag: "10.2.0"

service:
  port: 3000
  targetPort: 3000

ingress:
  enabled: true
  className: "traefik"
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - host: grafana.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: grafana-tls
      hosts:
        - grafana.theblacklodge.dev

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

persistence:
  enabled: true
  size: 10Gi

env:
  GF_SECURITY_ADMIN_PASSWORD: "admin123"
  GF_INSTALL_PLUGINS: "grafana-piechart-panel,grafana-worldmap-panel"

healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 5
```

### N8N Chart Update
```yaml
# k8s/n8n/values.yaml
image:
  repository: n8nio/n8n
  tag: "1.15.0"

service:
  port: 5678
  targetPort: 5678

ingress:
  enabled: true
  className: "traefik"
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - host: n8n.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: n8n-tls
      hosts:
        - n8n.theblacklodge.dev

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 300m
    memory: 512Mi

persistence:
  enabled: true
  size: 20Gi

env:
  N8N_HOST: "n8n.theblacklodge.dev"
  N8N_PORT: "5678"
  N8N_PROTOCOL: "https"
  WEBHOOK_URL: "https://n8n.theblacklodge.dev/"

healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /healthz
      port: 5678
    initialDelaySeconds: 60
    periodSeconds: 30
  readinessProbe:
    httpGet:
      path: /healthz
      port: 5678
    initialDelaySeconds: 10
    periodSeconds: 10
```

## ArgoCD Application Pattern

### Standard ArgoCD Application Template
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ app-name }}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/austindsmith/homelab-infra
    targetRevision: main
    path: k8s/{{ app-name }}
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ app-name }}
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
```

## Migration Strategy

### Phase 1: Standardize Existing Charts
1. Update Chart.yaml files for all applications
2. Standardize values.yaml structure
3. Add missing template files
4. Add resource specifications

### Phase 2: Implement Best Practices
1. Add health checks to all applications
2. Implement persistent storage where needed
3. Add proper security contexts
4. Configure resource limits and requests

### Phase 3: Optimize ArgoCD Deployment
1. Convert all applications to ArgoCD pattern
2. Implement App of Apps for complex deployments
3. Add proper sync policies and health checks
4. Set up monitoring and alerting

## Validation Checklist

Before deploying any chart, ensure:
- [ ] Chart.yaml is present and complete
- [ ] values.yaml follows standard structure
- [ ] Resource requests and limits are defined
- [ ] Health checks are configured
- [ ] Ingress is properly configured
- [ ] Persistent storage is configured if needed
- [ ] Security contexts are defined
- [ ] ArgoCD application is properly configured

This standardization will make your charts more maintainable, reliable, and easier to troubleshoot.
