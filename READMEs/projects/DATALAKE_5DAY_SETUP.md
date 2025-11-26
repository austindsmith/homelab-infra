# 5-Day Data Lakehouse Setup Guide 🚀

## Mission: Impress Dad with Modern Data Architecture

### Goal
Build a production-ready data lakehouse in 5 days to demonstrate modern data engineering capabilities, complete with real-time analytics, ML pipelines, and beautiful visualizations.

### Target Architecture
```
Data Sources → Airbyte → MinIO (S3) → Nessie (Catalog) → Dremio (Query Engine) → Superset (Visualization)
                    ↓
                Spark (Processing) → MLflow (ML Ops) → Jupyter (Analysis)
```

## Hardware Upgrade Plan

### Current Setup Analysis
- **Current**: Intel NUC with 32GB RAM
- **CPU**: Likely sufficient for demo workloads
- **Bottleneck**: Memory for data processing

### Recommended Upgrade Path
```bash
# Check current memory configuration
sudo dmidecode --type 17 | grep -E "(Size|Speed|Manufacturer)"

# Recommended upgrade options:
# Option 1 (Budget): Add 32GB stick → 64GB total (~$100-150)
# Option 2 (Performance): Replace with 2x32GB → 64GB dual channel (~$200-250)  
# Option 3 (Future-proof): Replace with 2x64GB → 128GB total (~$400-500)
```

**Recommendation**: Go with Option 2 (2x32GB) for best price/performance for demo.

### Best Buy Shopping List
- **Memory**: Crucial or Corsair 32GB DDR4-3200 SODIMM (2 sticks)
- **Storage** (if needed): Samsung 980 PRO 1TB NVMe SSD
- **Estimated Cost**: $200-300

## Day-by-Day Implementation Plan

### Day 1: Infrastructure Foundation
**Time**: 4-6 hours
**Goal**: Prepare cluster and storage foundation

#### Morning (2-3 hours): Hardware & Cluster Prep
```bash
# 1. Hardware upgrade (if purchasing)
# Install new RAM modules

# 2. Update cluster resources
cd /mnt/secondary_ssd/Code/homelab/infra/terraform
# Update variables.tf to use more resources for data nodes
vim variables.tf
# Increase memory to 6-8GB per VM for data workloads
```

#### Afternoon (2-3 hours): Storage Setup
```bash
# 3. Deploy MinIO for object storage
# 4. Set up persistent volumes for data workloads
# 5. Configure network policies for data stack
```

### Day 2: Core Data Platform
**Time**: 6-8 hours
**Goal**: Deploy Nessie, Dremio, and Airbyte

#### Morning: Data Catalog & Query Engine
- Deploy Nessie (data catalog with Git-like versioning)
- Deploy Dremio (distributed query engine)
- Configure MinIO integration

#### Afternoon: Data Ingestion
- Deploy Airbyte (data integration platform)
- Set up connectors for demo data sources
- Test data pipeline flow

### Day 3: Analytics & Processing
**Time**: 6-8 hours
**Goal**: Add Spark, Jupyter, and MLflow

#### Morning: Data Processing
- Deploy Spark cluster for distributed processing
- Deploy JupyterHub for interactive analysis
- Configure Spark-MinIO integration

#### Afternoon: ML Operations
- Deploy MLflow for ML lifecycle management
- Set up model registry and experiment tracking
- Create sample ML pipeline

### Day 4: Visualization & Demo Data
**Time**: 6-8 hours
**Goal**: Deploy Superset and create impressive demo

#### Morning: Visualization Platform
- Deploy Apache Superset for dashboards
- Configure Dremio as data source
- Create initial dashboard templates

#### Afternoon: Demo Data Pipeline
- Implement real-time data ingestion
- Create sample datasets (financial, IoT, social media)
- Build end-to-end data pipeline

### Day 5: Polish & Demo Preparation
**Time**: 4-6 hours
**Goal**: Final touches and demo rehearsal

#### Morning: Performance Optimization
- Optimize query performance
- Set up monitoring dashboards
- Test all components

#### Afternoon: Demo Preparation
- Create demo script and talking points
- Prepare sample queries and visualizations
- Final testing and backup plans

## Technical Stack Details

### Core Components

#### 1. MinIO (Object Storage)
```yaml
# k8s/minio/values.yaml
mode: distributed
replicas: 4
persistence:
  enabled: true
  size: 100Gi
resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1000m
ingress:
  enabled: true
  hosts:
    - minio.theblacklodge.dev
    - minio-console.theblacklodge.dev
```

#### 2. Nessie (Data Catalog)
```yaml
# k8s/nessie/values.yaml
image:
  repository: projectnessie/nessie
  tag: "0.74.0"
postgresql:
  enabled: true
  persistence:
    size: 20Gi
resources:
  requests:
    memory: 512Mi
    cpu: 250m
  limits:
    memory: 1Gi
    cpu: 500m
```

#### 3. Dremio (Query Engine)
```yaml
# k8s/dremio/values.yaml
coordinator:
  replicas: 1
  resources:
    requests:
      memory: 4Gi
      cpu: 1000m
    limits:
      memory: 8Gi
      cpu: 2000m
executor:
  replicas: 2
  resources:
    requests:
      memory: 8Gi
      cpu: 2000m
    limits:
      memory: 16Gi
      cpu: 4000m
```

#### 4. Airbyte (Data Integration)
```yaml
# k8s/airbyte/values.yaml
webapp:
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
server:
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
worker:
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
```

### Enhanced Stack Additions

#### 5. Apache Spark (Data Processing)
```yaml
# k8s/spark/values.yaml
master:
  resources:
    requests:
      memory: 2Gi
      cpu: 1000m
worker:
  replicas: 3
  resources:
    requests:
      memory: 4Gi
      cpu: 2000m
```

#### 6. JupyterHub (Interactive Analysis)
```yaml
# k8s/jupyterhub/values.yaml
hub:
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
singleuser:
  defaultUrl: "/lab"
  image:
    name: jupyter/datascience-notebook
    tag: "latest"
  memory:
    limit: 4G
    guarantee: 2G
  cpu:
    limit: 2
    guarantee: 1
```

#### 7. MLflow (ML Operations)
```yaml
# k8s/mlflow/values.yaml
tracking:
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
postgresql:
  enabled: true
  persistence:
    size: 20Gi
```

#### 8. Apache Superset (Visualization)
```yaml
# k8s/superset/values.yaml
resources:
  requests:
    memory: 2Gi
    cpu: 1000m
  limits:
    memory: 4Gi
    cpu: 2000m
postgresql:
  enabled: true
redis:
  enabled: true
```

## Demo Project: "Smart City Analytics Platform"

### Project Overview
Build a real-time smart city analytics platform that ingests, processes, and visualizes multiple data streams to demonstrate the full data lakehouse capabilities.

### Data Sources (Simulated but Realistic)
1. **IoT Sensor Data**: Temperature, humidity, air quality, noise levels
2. **Traffic Data**: Vehicle counts, speed, congestion patterns
3. **Weather Data**: Real weather API integration
4. **Social Media**: Twitter sentiment about city services
5. **Energy Usage**: Simulated smart meter data
6. **Public Transit**: Bus/train schedules and delays

### Demo Scenarios

#### Scenario 1: Real-time City Dashboard
```sql
-- Live city metrics query in Dremio
SELECT 
    sensor_location,
    AVG(temperature) as avg_temp,
    AVG(air_quality_index) as avg_aqi,
    COUNT(*) as sensor_readings
FROM nessie.city_sensors.iot_data 
WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '1' HOUR
GROUP BY sensor_location
ORDER BY avg_aqi DESC;
```

#### Scenario 2: Predictive Analytics
```python
# ML model in Jupyter for traffic prediction
import mlflow
import pandas as pd
from sklearn.ensemble import RandomForestRegressor

# Load data from Dremio via Arrow Flight
data = dremio_client.query("""
    SELECT * FROM nessie.traffic.hourly_counts 
    WHERE date >= '2024-01-01'
""")

# Train model
model = RandomForestRegressor()
model.fit(X_train, y_train)

# Log to MLflow
mlflow.sklearn.log_model(model, "traffic_predictor")
```

#### Scenario 3: Data Lineage & Governance
```bash
# Show data versioning with Nessie
curl -X GET "http://nessie.theblacklodge.dev/api/v1/trees/main/log" | jq

# Demonstrate data catalog features
# Show table schemas, data quality metrics, lineage
```

### Impressive Demo Features

#### 1. Real-time Data Pipeline
- Live data streaming from multiple sources
- Real-time aggregations and alerts
- Sub-second query responses

#### 2. Time Travel Queries
```sql
-- Query data as it existed yesterday
SELECT * FROM nessie.city_sensors.iot_data 
AT BRANCH main AS OF '2024-11-21T10:00:00'
```

#### 3. ML Pipeline Automation
- Automated model training on new data
- A/B testing of model versions
- Real-time model serving

#### 4. Interactive Dashboards
- City overview dashboard with live metrics
- Drill-down capabilities from city → district → sensor
- Predictive analytics visualizations

## Resource Requirements

### Minimum Cluster Specs (Post-Upgrade)
```yaml
Total Resources Needed:
  Memory: 48-64GB (across all nodes)
  CPU: 20-24 cores
  Storage: 500GB+ for data
  
Per-Node Recommendation:
  Memory: 8-12GB per VM
  CPU: 3-4 cores per VM
  Nodes: 5-6 VMs total
```

### Storage Layout
```bash
# Recommended storage allocation
MinIO: 200GB (distributed across nodes)
PostgreSQL DBs: 100GB total
Spark temp: 50GB
Jupyter notebooks: 20GB
MLflow artifacts: 30GB
Logs & monitoring: 50GB
```

## Performance Optimization Tips

### 1. Memory Tuning
```yaml
# JVM settings for Dremio
DREMIO_MAX_HEAP_MEMORY_SIZE_MB: 6144
DREMIO_MAX_DIRECT_MEMORY_SIZE_MB: 8192

# Spark configuration
spark.executor.memory: 4g
spark.executor.cores: 2
spark.sql.adaptive.enabled: true
```

### 2. Query Optimization
```sql
-- Use partitioning for better performance
CREATE TABLE nessie.sensors.iot_data_partitioned (
    sensor_id VARCHAR,
    temperature DOUBLE,
    timestamp TIMESTAMP
) PARTITIONED BY (DATE(timestamp))
```

### 3. Caching Strategy
```python
# Cache frequently accessed datasets in Dremio
# Use reflection acceleration for common queries
# Implement Redis caching for Superset
```

## Monitoring & Observability

### Key Metrics to Track
1. **Query Performance**: Response times, throughput
2. **Resource Utilization**: Memory, CPU, storage usage
3. **Data Pipeline Health**: Ingestion rates, error rates
4. **ML Model Performance**: Accuracy, drift detection

### Monitoring Stack
```yaml
# Add to existing monitoring
- Prometheus metrics from all components
- Grafana dashboards for data platform
- Alert rules for pipeline failures
- Custom metrics for business KPIs
```

## Demo Script Outline

### Opening (2 minutes)
"Today I'll show you a modern data lakehouse that can handle petabytes of data, provide real-time analytics, and support machine learning at scale - all running on my homelab."

### Architecture Overview (3 minutes)
- Show the complete data flow
- Explain each component's role
- Highlight key benefits (scalability, flexibility, cost)

### Live Demo (10 minutes)
1. **Data Ingestion**: Show Airbyte pulling live data
2. **Real-time Processing**: Spark job processing streaming data
3. **Interactive Analysis**: Jupyter notebook with live queries
4. **ML Pipeline**: Model training and deployment
5. **Visualization**: Superset dashboard with live updates

### Technical Deep Dive (5 minutes)
- Show Nessie data versioning
- Demonstrate query federation across sources
- Explain cost savings vs traditional data warehouse

### Q&A and Discussion (5 minutes)

## Troubleshooting Guide

### Common Issues
1. **Memory Pressure**: Scale down replicas, optimize JVM settings
2. **Slow Queries**: Check data partitioning, add reflections
3. **Network Issues**: Verify service mesh configuration
4. **Storage Full**: Implement data lifecycle policies

### Emergency Backup Plan
- Have pre-recorded demo video ready
- Prepare static dashboards as fallback
- Keep architecture diagrams handy
- Practice demo multiple times

## Success Metrics

### Technical Success
- [ ] All components deployed and healthy
- [ ] End-to-end data pipeline working
- [ ] Sub-second query responses for demo queries
- [ ] ML pipeline training and serving models
- [ ] Real-time dashboards updating

### Demo Success
- [ ] Smooth 15-minute presentation
- [ ] All live demos work flawlessly
- [ ] Dad asks technical follow-up questions
- [ ] Clear explanation of business value
- [ ] Impressive "wow factor" moments

This ambitious 5-day plan will create a genuinely impressive data platform that showcases modern data engineering capabilities. The key is starting with solid infrastructure (Day 1) and building incrementally while testing each component thoroughly.

Ready to build something amazing? 🚀
