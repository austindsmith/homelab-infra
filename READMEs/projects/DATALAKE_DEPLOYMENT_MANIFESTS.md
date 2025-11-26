# Data Lakehouse Deployment Manifests

## Quick Deployment Commands

### Prerequisites
```bash
# Ensure cluster has sufficient resources
kubectl top nodes

# Create data namespace
kubectl create namespace datalake

# Set default namespace
kubens datalake
```

## Day 1: Storage Foundation

### MinIO Deployment
```bash
# Add MinIO Helm repo
helm repo add minio https://charts.min.io/
helm repo update

# Deploy MinIO
helm install minio minio/minio \
  --namespace datalake \
  --set mode=distributed \
  --set replicas=4 \
  --set persistence.enabled=true \
  --set persistence.size=50Gi \
  --set resources.requests.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=minio.theblacklodge.dev \
  --set consoleIngress.enabled=true \
  --set consoleIngress.hosts[0]=minio-console.theblacklodge.dev
```

### MinIO Configuration
```yaml
# k8s/minio/values.yaml
mode: distributed
replicas: 4

auth:
  rootUser: admin
  rootPassword: minio123

persistence:
  enabled: true
  storageClass: "local-path"
  size: 50Gi

resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1000m

ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - minio.theblacklodge.dev
  tls:
    - secretName: minio-tls
      hosts:
        - minio.theblacklodge.dev

consoleIngress:
  enabled: true
  ingressClassName: traefik
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - minio-console.theblacklodge.dev
  tls:
    - secretName: minio-console-tls
      hosts:
        - minio-console.theblacklodge.dev

buckets:
  - name: datalake
    policy: none
    purge: false
  - name: warehouse
    policy: none
    purge: false
  - name: mlflow
    policy: none
    purge: false
```

## Day 2: Data Catalog & Query Engine

### PostgreSQL for Nessie
```yaml
# k8s/postgresql/values.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: datalake
type: Opaque
data:
  postgres-password: cG9zdGdyZXM=  # postgres
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  namespace: datalake
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: nessie
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: datalake
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
  namespace: datalake
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
```

### Nessie Deployment
```yaml
# k8s/nessie/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nessie
  namespace: datalake
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nessie
  template:
    metadata:
      labels:
        app: nessie
    spec:
      containers:
      - name: nessie
        image: projectnessie/nessie:0.74.0
        ports:
        - containerPort: 19120
        env:
        - name: QUARKUS_DATASOURCE_JDBC_URL
          value: "jdbc:postgresql://postgresql:5432/nessie"
        - name: QUARKUS_DATASOURCE_USERNAME
          value: "postgres"
        - name: QUARKUS_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        - name: NESSIE_VERSION_STORE_TYPE
          value: "JDBC"
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: nessie
  namespace: datalake
spec:
  selector:
    app: nessie
  ports:
  - port: 19120
    targetPort: 19120
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nessie-ingress
  namespace: datalake
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - nessie.theblacklodge.dev
      secretName: nessie-tls
  rules:
    - host: nessie.theblacklodge.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nessie
                port:
                  number: 19120
```

### Dremio Deployment
```bash
# Add Dremio Helm repo
helm repo add dremio https://charts.dremio.com
helm repo update

# Deploy Dremio
helm install dremio dremio/dremio \
  --namespace datalake \
  --set coordinator.count=1 \
  --set coordinator.memory=4096 \
  --set coordinator.cpu=2 \
  --set executor.count=2 \
  --set executor.memory=8192 \
  --set executor.cpu=4 \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=dremio.theblacklodge.dev
```

### Dremio Values Override
```yaml
# k8s/dremio/values.yaml
coordinator:
  count: 1
  memory: 4096
  cpu: 2
  volumeSize: 20Gi

executor:
  count: 2
  memory: 8192
  cpu: 4
  volumeSize: 50Gi

zookeeper:
  count: 1
  memory: 1024
  cpu: 0.5
  volumeSize: 10Gi

ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - dremio.theblacklodge.dev
  tls:
    - secretName: dremio-tls
      hosts:
        - dremio.theblacklodge.dev

# MinIO connection configuration
extraStartParams: >-
  -Ddremio.s3.compat=true
  -Dcom.dremio.exec.hadoop.fs.s3a.access.key=admin
  -Dcom.dremio.exec.hadoop.fs.s3a.secret.key=minio123
```

## Day 2 Continued: Airbyte

### Airbyte Deployment
```bash
# Add Airbyte Helm repo
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update

# Deploy Airbyte
helm install airbyte airbyte/airbyte \
  --namespace datalake \
  --set webapp.ingress.enabled=true \
  --set webapp.ingress.hosts[0]=airbyte.theblacklodge.dev \
  --set postgresql.enabled=true
```

### Airbyte Values
```yaml
# k8s/airbyte/values.yaml
webapp:
  replicaCount: 1
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
    limits:
      memory: 1Gi
      cpu: 500m
  ingress:
    enabled: true
    className: traefik
    annotations:
      kubernetes.io/ingress.class: "traefik"
      cert-manager.io/cluster-issuer: "letsencrypt-dns"
    hosts:
      - host: airbyte.theblacklodge.dev
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: airbyte-tls
        hosts:
          - airbyte.theblacklodge.dev

server:
  replicaCount: 1
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 1000m

worker:
  replicaCount: 1
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
    limits:
      memory: 4Gi
      cpu: 2000m

postgresql:
  enabled: true
  auth:
    postgresPassword: airbyte
  primary:
    persistence:
      size: 20Gi
```

## Day 3: Spark & Jupyter

### Spark Operator
```bash
# Install Spark Operator
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm repo update

helm install spark-operator spark-operator/spark-operator \
  --namespace datalake \
  --set sparkJobNamespace=datalake \
  --set webhook.enable=true
```

### JupyterHub Deployment
```bash
# Add JupyterHub Helm repo
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

# Deploy JupyterHub
helm install jupyterhub jupyterhub/jupyterhub \
  --namespace datalake \
  --values k8s/jupyterhub/values.yaml
```

### JupyterHub Values
```yaml
# k8s/jupyterhub/values.yaml
hub:
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
    limits:
      memory: 1Gi
      cpu: 500m

proxy:
  service:
    type: ClusterIP
  chp:
    resources:
      requests:
        memory: 256Mi
        cpu: 100m

singleuser:
  defaultUrl: "/lab"
  image:
    name: jupyter/datascience-notebook
    tag: "python-3.11"
  memory:
    limit: 4G
    guarantee: 2G
  cpu:
    limit: 2
    guarantee: 1
  storage:
    capacity: 10Gi
    homeMountPath: /home/jovyan
  extraEnv:
    DREMIO_HOST: "dremio.datalake.svc.cluster.local"
    MINIO_ENDPOINT: "minio.datalake.svc.cluster.local:9000"

ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - jupyter.theblacklodge.dev
  tls:
    - secretName: jupyter-tls
      hosts:
        - jupyter.theblacklodge.dev

auth:
  type: dummy
  dummy:
    password: "jupyter"
```

### MLflow Deployment
```yaml
# k8s/mlflow/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mlflow
  namespace: datalake
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mlflow
  template:
    metadata:
      labels:
        app: mlflow
    spec:
      containers:
      - name: mlflow
        image: python:3.9-slim
        command:
        - /bin/bash
        - -c
        - |
          pip install mlflow boto3 psycopg2-binary
          mlflow server \
            --backend-store-uri postgresql://postgres:postgres@postgresql:5432/mlflow \
            --default-artifact-root s3://mlflow/ \
            --host 0.0.0.0 \
            --port 5000
        ports:
        - containerPort: 5000
        env:
        - name: AWS_ACCESS_KEY_ID
          value: "admin"
        - name: AWS_SECRET_ACCESS_KEY
          value: "minio123"
        - name: MLFLOW_S3_ENDPOINT_URL
          value: "http://minio:9000"
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1000m
---
apiVersion: v1
kind: Service
metadata:
  name: mlflow
  namespace: datalake
spec:
  selector:
    app: mlflow
  ports:
  - port: 5000
    targetPort: 5000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mlflow-ingress
  namespace: datalake
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - mlflow.theblacklodge.dev
      secretName: mlflow-tls
  rules:
    - host: mlflow.theblacklodge.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mlflow
                port:
                  number: 5000
```

## Day 4: Superset

### Superset Deployment
```bash
# Add Superset Helm repo
helm repo add superset https://apache.github.io/superset
helm repo update

# Deploy Superset
helm install superset superset/superset \
  --namespace datalake \
  --values k8s/superset/values.yaml
```

### Superset Values
```yaml
# k8s/superset/values.yaml
supersetNode:
  replicaCount: 1
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
    limits:
      memory: 4Gi
      cpu: 2000m

supersetWorker:
  replicaCount: 1
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 1000m

postgresql:
  enabled: true
  auth:
    postgresPassword: superset
  primary:
    persistence:
      size: 20Gi

redis:
  enabled: true
  auth:
    enabled: false

ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    kubernetes.io/ingress.class: "traefik"
    cert-manager.io/cluster-issuer: "letsencrypt-dns"
  hosts:
    - host: superset.theblacklodge.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: superset-tls
      hosts:
        - superset.theblacklodge.dev

init:
  adminUser:
    username: admin
    firstname: Admin
    lastname: User
    email: admin@superset.com
    password: admin

configOverrides:
  enable_oauth: |
    # OAuth configuration if needed
  my_override: |
    # Custom Superset configuration
```

## Sample Data Generation

### Data Generator Job
```yaml
# k8s/data-generator/job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-generator
  namespace: datalake
spec:
  template:
    spec:
      containers:
      - name: generator
        image: python:3.9-slim
        command:
        - /bin/bash
        - -c
        - |
          pip install pandas boto3 faker numpy
          python3 << 'EOF'
          import pandas as pd
          import numpy as np
          from faker import Faker
          import boto3
          from datetime import datetime, timedelta
          import json
          
          # Initialize
          fake = Faker()
          s3 = boto3.client(
              's3',
              endpoint_url='http://minio:9000',
              aws_access_key_id='admin',
              aws_secret_access_key='minio123'
          )
          
          # Generate IoT sensor data
          def generate_iot_data(num_records=10000):
              data = []
              for i in range(num_records):
                  data.append({
                      'sensor_id': f'sensor_{i % 100}',
                      'location': fake.city(),
                      'temperature': np.random.normal(20, 5),
                      'humidity': np.random.uniform(30, 90),
                      'air_quality': np.random.uniform(0, 500),
                      'timestamp': fake.date_time_between(start_date='-30d', end_date='now')
                  })
              return pd.DataFrame(data)
          
          # Generate traffic data
          def generate_traffic_data(num_records=5000):
              data = []
              for i in range(num_records):
                  data.append({
                      'intersection_id': f'int_{i % 50}',
                      'vehicle_count': np.random.poisson(20),
                      'avg_speed': np.random.normal(45, 10),
                      'congestion_level': np.random.choice(['low', 'medium', 'high']),
                      'timestamp': fake.date_time_between(start_date='-7d', end_date='now')
                  })
              return pd.DataFrame(data)
          
          # Generate and upload data
          print("Generating IoT data...")
          iot_df = generate_iot_data()
          iot_df.to_parquet('/tmp/iot_data.parquet')
          s3.upload_file('/tmp/iot_data.parquet', 'datalake', 'iot/iot_data.parquet')
          
          print("Generating traffic data...")
          traffic_df = generate_traffic_data()
          traffic_df.to_parquet('/tmp/traffic_data.parquet')
          s3.upload_file('/tmp/traffic_data.parquet', 'datalake', 'traffic/traffic_data.parquet')
          
          print("Data generation complete!")
          EOF
      restartPolicy: Never
  backoffLimit: 3
```

## Deployment Script

### Complete Deployment Automation
```bash
#!/bin/bash
# deploy-datalake.sh

set -e

echo "🚀 Starting Data Lakehouse Deployment..."

# Check prerequisites
echo "Checking prerequisites..."
kubectl cluster-info
helm version

# Create namespace
kubectl create namespace datalake --dry-run=client -o yaml | kubectl apply -f -
kubens datalake

# Day 1: Storage
echo "📦 Day 1: Deploying storage layer..."
helm repo add minio https://charts.min.io/
helm repo update
helm upgrade --install minio minio/minio --namespace datalake -f k8s/minio/values.yaml

# Wait for MinIO
kubectl wait --for=condition=ready pod -l app=minio -n datalake --timeout=300s

# Day 2: Data Platform
echo "🗄️ Day 2: Deploying data platform..."
kubectl apply -f k8s/postgresql/
kubectl wait --for=condition=ready pod -l app=postgresql -n datalake --timeout=300s

kubectl apply -f k8s/nessie/
kubectl wait --for=condition=ready pod -l app=nessie -n datalake --timeout=300s

helm repo add dremio https://charts.dremio.com
helm upgrade --install dremio dremio/dremio --namespace datalake -f k8s/dremio/values.yaml

helm repo add airbyte https://airbytehq.github.io/helm-charts
helm upgrade --install airbyte airbyte/airbyte --namespace datalake -f k8s/airbyte/values.yaml

# Day 3: Analytics
echo "🔬 Day 3: Deploying analytics layer..."
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm upgrade --install spark-operator spark-operator/spark-operator --namespace datalake

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm upgrade --install jupyterhub jupyterhub/jupyterhub --namespace datalake -f k8s/jupyterhub/values.yaml

kubectl apply -f k8s/mlflow/

# Day 4: Visualization
echo "📊 Day 4: Deploying visualization layer..."
helm repo add superset https://apache.github.io/superset
helm upgrade --install superset superset/superset --namespace datalake -f k8s/superset/values.yaml

# Generate sample data
echo "🎲 Generating sample data..."
kubectl apply -f k8s/data-generator/job.yaml

echo "✅ Deployment complete!"
echo ""
echo "🌐 Access URLs:"
echo "MinIO Console: https://minio-console.theblacklodge.dev"
echo "Nessie: https://nessie.theblacklodge.dev"
echo "Dremio: https://dremio.theblacklodge.dev"
echo "Airbyte: https://airbyte.theblacklodge.dev"
echo "Jupyter: https://jupyter.theblacklodge.dev"
echo "MLflow: https://mlflow.theblacklodge.dev"
echo "Superset: https://superset.theblacklodge.dev"
echo ""
echo "🔑 Default Credentials:"
echo "MinIO: admin/minio123"
echo "Jupyter: any username/jupyter"
echo "Superset: admin/admin"
```

This comprehensive deployment guide provides all the manifests and automation needed to get your data lakehouse running quickly. The automated deployment script will handle the entire process, making it easy to rebuild if needed during your 5-day sprint.
