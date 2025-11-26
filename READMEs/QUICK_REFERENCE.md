# 🚀 Quick Reference Card

**For detailed guides, see [USER_GUIDE.md](READMEs/USER_GUIDE.md)**

## 📱 Application URLs

### Media Stack
```
Homepage:    http://homepage.theblacklodge.dev
Radarr:      http://radarr.theblacklodge.dev
Sonarr:      http://sonarr.theblacklodge.dev
Lidarr:      http://lidarr.theblacklodge.dev
Prowlarr:    http://prowlarr.theblacklodge.dev
Overseerr:   http://overseerr.theblacklodge.dev
qBittorrent: http://qbittorrent.theblacklodge.dev
```

### Data Lakehouse
```
MinIO:       http://minio-console.theblacklodge.dev
Nessie:      http://nessie.theblacklodge.dev:19120
Dremio:      http://dremio.theblacklodge.dev
Airbyte:     http://airbyte.theblacklodge.dev
Spark:       http://spark.theblacklodge.dev
JupyterHub:  http://jupyter.theblacklodge.dev
MLflow:      http://mlflow.theblacklodge.dev
Superset:    http://superset.theblacklodge.dev
```

### Tools
```
Gitea:       http://gitea.theblacklodge.dev
n8n:         http://n8n.theblacklodge.dev
Vaultwarden: http://vaultwarden.theblacklodge.dev
pgAdmin:     http://pgadmin.theblacklodge.dev
Grafana:     http://grafana.theblacklodge.dev
```

## 🔑 Quick Credentials

See [CREDENTIALS.md](CREDENTIALS.md) for complete list.

**MinIO**:
- Access Key: `7t2BEhZXXbQCnfyvQrZW`
- Secret Key: `m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw`

**Dremio**: admin / Dremio123!
**Superset**: admin / admin
**PostgreSQL**: postgres / postgres123

## 🎯 Common Tasks

### Upload Data to MinIO
```python
import boto3
s3 = boto3.client('s3',
    endpoint_url='http://minio.theblacklodge.dev',
    aws_access_key_id='7t2BEhZXXbQCnfyvQrZW',
    aws_secret_access_key='m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw'
)
s3.upload_file('local.csv', 'raw-data', 'data/file.csv')
```

### Query in Dremio
```sql
SELECT * FROM minio."raw-data".data."file.csv" LIMIT 10;
```

### Process with Spark (in Jupyter)
```python
df = spark.read.csv("s3a://raw-data/data/file.csv", header=True)
df_clean = df.filter(df.value > 0)
df_clean.write.parquet("s3a://processed-data/output/")
```

### Check Pod Status
```bash
kubectl get pods -A
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

## 📊 Recommended First Projects

1. **COVID-19 Analysis** - Public dataset, easy to start
2. **Personal Finance** - Track expenses, create budgets
3. **Weather Tracking** - API integration, time series
4. **Media Stats** - Analyze your Radarr/Sonarr data

See [USER_GUIDE.md](READMEs/USER_GUIDE.md) for detailed workflows!

## 🆘 Quick Troubleshooting

**App won't start**: `kubectl get pods -n <namespace>`
**Can't access**: `kubectl get ingress -A`
**Storage issue**: `kubectl get pvc -A`
**Check logs**: `kubectl logs -f <pod-name> -n <namespace>`

## 📚 Documentation

- **Complete Guide**: [READMEs/USER_GUIDE.md](READMEs/USER_GUIDE.md)
- **Credentials**: [CREDENTIALS.md](CREDENTIALS.md)
- **Infrastructure**: [README.md](README.md)

