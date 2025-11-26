# ArgoCD Access Information

## ✅ ArgoCD is Running and Accessible!

### Status
All ArgoCD components are healthy and operational:
```
✅ argocd-application-controller  - Running
✅ argocd-applicationset-controller - Running
✅ argocd-dex-server - Running
✅ argocd-notifications-controller - Running
✅ argocd-redis - Running
✅ argocd-repo-server - Running
✅ argocd-server - Running
```

## 🌐 Access URLs

### Via Ingress (Recommended)
```
http://argocd.theblacklodge.dev
```

### Via NodePort (Direct Access)
```
http://192.168.50.15:30379
http://192.168.50.16:30379
http://192.168.50.17:30379
```

## 🔐 Login Credentials

### Username
```
admin
```

### Password
```
F43ilMMGxMj1YMYE
```

**⚠️ IMPORTANT**: Change this password after first login!

## 🔧 Change Password

After logging in, change the password:

### Via UI
1. Go to User Info (top right)
2. Click "Update Password"
3. Enter current password: `F43ilMMGxMj1YMYE`
4. Enter new password
5. Confirm

### Via CLI
```bash
# Login first
argocd login argocd.theblacklodge.dev --username admin --password F43ilMMGxMj1YMYE

# Change password
argocd account update-password
```

## 📦 Configuration

### Insecure Mode
ArgoCD is configured to run in insecure mode (HTTP) via ConfigMap:
```yaml
server.insecure: "true"
```

This allows it to work with HTTP ingress (Traefik).

### Ingress Configuration
```yaml
Host: argocd.theblacklodge.dev
Path: /
Backend: argocd-server:80
Annotations:
  - kubernetes.io/ingress.class: traefik
  - traefik.ingress.kubernetes.io/router.entrypoints: web
```

## 🚀 Getting Started

### 1. Access the UI
Open http://argocd.theblacklodge.dev in your browser

### 2. Login
- Username: `admin`
- Password: `F43ilMMGxMj1YMYE`

### 3. Change Password
Follow the steps above to change the default password

### 4. Add a Repository
1. Go to Settings → Repositories
2. Click "Connect Repo"
3. Choose connection method (HTTPS/SSH)
4. Enter repository URL
5. Add credentials if needed
6. Click "Connect"

### 5. Create an Application
1. Go to Applications
2. Click "+ New App"
3. Fill in:
   - Application Name
   - Project: default
   - Sync Policy: Automatic (optional)
   - Repository URL
   - Path to manifests
   - Cluster: https://kubernetes.default.svc
   - Namespace: target namespace
4. Click "Create"

## 📚 Useful Commands

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get ingress -n argocd
```

### View ArgoCD Server Logs
```bash
kubectl logs -n argocd deployment/argocd-server -f
```

### Restart ArgoCD Server
```bash
kubectl rollout restart deployment argocd-server -n argocd
```

### Get Admin Password
```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d
```

## 🔗 Integration with Your Apps

ArgoCD can manage all your Kubernetes applications:

### Example: Deploy from Git
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/your-repo
    targetRevision: main
    path: k8s/apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## ✅ Verification

ArgoCD is confirmed working:
- ✅ All 7 components running
- ✅ HTTP 200 response from server
- ✅ Ingress configured correctly
- ✅ NodePort accessible
- ✅ Admin credentials available

**ArgoCD is ready for GitOps deployments!** 🚀

---

**Last Verified**: November 24, 2025, 7:25 AM UTC
**Version**: ArgoCD (latest from deployment)
**Status**: 🟢 Fully Operational

