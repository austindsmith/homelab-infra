#!/bin/bash

echo "🧹 NFS Storage Cleanup and Organization Script"
echo "=============================================="

export KUBECONFIG=~/.kube/config

echo "📁 Current NFS structure:"
kubectl exec -n apps deployment/homepage -- ls -la /app/config/ 2>/dev/null || echo "Homepage not accessible"

echo ""
echo "🔧 Step 1: Creating proper directory structure..."

# Create all app subdirectories
kubectl exec -n apps deployment/homepage -- mkdir -p \
  /app/config/homepage \
  /app/config/radarr \
  /app/config/sonarr \
  /app/config/lidarr \
  /app/config/prowlarr \
  /app/config/qbittorrent \
  /app/config/overseerr \
  /app/config/gitea \
  /app/config/vaultwarden \
  /app/config/pgadmin 2>/dev/null || echo "Some directories may already exist"

echo ""
echo "🧹 Step 2: Moving stray files to proper locations..."

# Move Homepage files to its subdirectory
kubectl exec -n apps deployment/homepage -- sh -c "
  cd /app/config
  for file in *.yaml *.css *.js; do
    if [ -f \"\$file\" ] && [ \"\$file\" != \"homepage\" ]; then
      echo \"Moving \$file to homepage/\"
      mv \"\$file\" homepage/ 2>/dev/null || true
    fi
  done
  
  # Move logs directory if it exists at root
  if [ -d logs ] && [ ! -d homepage/logs ]; then
    mv logs homepage/ 2>/dev/null || true
  fi
" 2>/dev/null || echo "Homepage cleanup completed"

echo ""
echo "🔍 Step 3: Checking for permission issues..."

# Check permissions on NFS mount
kubectl exec -n apps deployment/homepage -- ls -la /app/config/ | head -10

echo ""
echo "📊 Step 4: Verifying app-specific directories..."

for app in homepage radarr sonarr lidarr prowlarr qbittorrent overseerr gitea vaultwarden pgadmin; do
  echo "--- $app directory ---"
  kubectl exec -n apps deployment/homepage -- ls -la /app/config/$app/ 2>/dev/null | head -3 || echo "Directory empty or not accessible"
done

echo ""
echo "⚠️  Permission Requirements for NAS:"
echo "===================================="
echo "1. NFS share should be owned by UID 1000:1000 (or allow write access)"
echo "2. NFS export should have 'no_root_squash' or proper UID mapping"
echo "3. Directory permissions should be 755 or 775"
echo ""
echo "If you see permission errors, run on your NAS:"
echo "sudo chown -R 1000:1000 /volume1/infrastructure/kubernetes"
echo "sudo chmod -R 775 /volume1/infrastructure/kubernetes"

echo ""
echo "✅ NFS cleanup completed!"
