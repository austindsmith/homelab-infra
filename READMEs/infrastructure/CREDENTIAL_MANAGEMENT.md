# Credential Management Guide

## 🔐 Security Overview

This infrastructure uses a centralized credential management system to keep sensitive data secure and out of version control.

## 📁 File Structure

```
k8s/
├── global-secrets.yaml.template    # Template for secrets (committed)
├── global-secrets.yaml            # Actual secrets (NOT committed)
├── global-values.yaml             # Non-sensitive global config (committed)
└── [apps]/values.yaml             # Reference global secrets (committed)

scripts/
└── manage-credentials.sh          # Credential management utility
```

## 🚨 Critical Security Rules

### ✅ DO:
- Use `global-secrets.yaml` for all sensitive data
- Reference secrets in Helm values using templates: `{{ .Values.global.credentials.secretName }}`
- Keep `global-secrets.yaml` in `.gitignore`
- Use the credential management script
- Generate strong passwords (25+ characters)

### ❌ DON'T:
- Hardcode passwords in any committed files
- Put API keys directly in values.yaml files
- Commit any `.env` files with credentials
- Share credentials in chat/email

## 🛠️ Setup Process

### 1. Generate Secrets File
```bash
cd /mnt/secondary_ssd/Code/homelab/infra
./scripts/manage-credentials.sh create
```

### 2. Edit Cloudflare Token
```bash
# Edit the generated file and set your Cloudflare API token
nano k8s/global-secrets.yaml
```

### 3. Apply to Cluster
```bash
./scripts/manage-credentials.sh apply
```

### 4. Clean Up Any Remaining Hardcoded Credentials
```bash
./scripts/manage-credentials.sh cleanup
```

## 📋 Current Credentials Managed

### MinIO Object Storage
- **User**: `minio-root-user`
- **Password**: `minio-root-password`
- **Usage**: Object storage for MLflow, Spark, etc.

### PostgreSQL Databases
- **Superset DB**: `postgres-superset-password`
- **Airbyte DB**: `postgres-airbyte-password`
- **MLflow DB**: `postgres-mlflow-password`
- **Nessie DB**: `postgres-nessie-password`

### Application Admin Accounts
- **Superset Admin**: `superset-admin-password`

### External Services
- **Cloudflare API**: `cloudflare-api-token`

## 🔧 Using Secrets in Helm Charts

### In values.yaml files:
```yaml
# Instead of hardcoding:
password: "hardcoded123"  # ❌ DON'T DO THIS

# Use template reference:
password: "{{ .Values.global.credentials.secretName | default \"fallback\" }}"  # ✅ DO THIS
```

### In templates:
```yaml
# Reference from global secret
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: global-credentials
      key: postgres-superset-password
```

## 🔍 Accessing Credentials

### View Available Secrets (Masked)
```bash
./scripts/manage-credentials.sh show
```

### Extract Credentials for Web UIs
```bash
./scripts/extract-credentials.sh
```

### Manual Kubernetes Access
```bash
# Get all secret keys
kubectl get secret global-credentials -o jsonpath='{.data}' | jq -r 'keys[]'

# Get specific password (base64 decoded)
kubectl get secret global-credentials -o jsonpath='{.data.minio-root-password}' | base64 -d
```

## 🔄 Credential Rotation

### To Update Passwords:
1. Edit `k8s/global-secrets.yaml`
2. Apply changes: `./scripts/manage-credentials.sh apply`
3. Restart affected applications: `kubectl rollout restart deployment/app-name -n namespace`

### To Generate New Random Passwords:
```bash
# Generate new secrets file (will prompt to overwrite)
./scripts/manage-credentials.sh create
```

## 🚨 Emergency Procedures

### If Credentials Are Accidentally Committed:
1. **Immediately** change all passwords
2. Force push to remove from git history:
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch path/to/file' --prune-empty --tag-name-filter cat -- --all
   git push origin --force --all
   ```
3. Regenerate and apply new credentials
4. Restart all affected services

### If Cluster Access Is Lost:
1. SSH to any node: `ssh root@192.168.50.15`
2. Access secrets directly:
   ```bash
   k3s kubectl get secret global-credentials -o yaml
   ```
3. Decode base64 values to recover passwords

## 📊 Credential Audit

### Files That Should NOT Contain Credentials:
- ✅ All `values.yaml` files (use templates)
- ✅ All `Chart.yaml` files
- ✅ All scripts in `scripts/` directory
- ✅ All Ansible playbooks
- ✅ All Terraform files

### Files That MAY Contain Credentials:
- ⚠️ `k8s/global-secrets.yaml` (not committed)
- ⚠️ `CREDENTIALS_EXTRACTED.md` (not committed)
- ⚠️ Docker `.env` files (not committed)

## 🔗 Integration with Applications

### Helm Deployment with Global Secrets:
```bash
# Deploy with global values
helm install app-name ./k8s/datalake/superset \
  -f k8s/global-values.yaml \
  --set global.credentials.supersetAdminPassword="$(kubectl get secret global-credentials -o jsonpath='{.data.superset-admin-password}' | base64 -d)"
```

### ArgoCD Integration:
ArgoCD applications automatically use the global secrets when they're applied to the cluster.

## 📝 Best Practices

1. **Principle of Least Privilege**: Only give applications access to secrets they need
2. **Regular Rotation**: Change passwords quarterly or after any security incident
3. **Monitoring**: Monitor secret access in Kubernetes audit logs
4. **Backup**: Keep encrypted backups of critical credentials
5. **Documentation**: Keep `CREDENTIALS.md` updated with current access information

## 🆘 Support

If you need help with credential management:
1. Check this guide first
2. Run `./scripts/manage-credentials.sh help`
3. Check `.gitignore` to ensure sensitive files are excluded
4. Verify no credentials are in committed files: `git log --all -S "password" --source --all`
