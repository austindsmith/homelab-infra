# 🎯 Homelab Applications - Complete User Guide

**Last Updated**: November 24, 2025

This guide covers all applications in your homelab and provides detailed workflows for using your data lakehouse platform.

## 📑 Table of Contents

1. [Quick Access URLs](#quick-access-urls)
2. [Media Management Stack](#media-management-stack)
3. [Data Lakehouse Platform](#data-lakehouse-platform)
4. [Development & Automation](#development--automation)
5. [Monitoring & Management](#monitoring--management)
6. [Complete Data Lakehouse Workflows](#complete-data-lakehouse-workflows)
7. [Project Ideas & Use Cases](#project-ideas--use-cases)

---

## 🔗 Quick Access URLs

### Media Apps
- **Homepage**: http://homepage.theblacklodge.dev (Dashboard)
- **Radarr**: http://radarr.theblacklodge.dev (Movies)
- **Sonarr**: http://sonarr.theblacklodge.dev (TV Shows)
- **Lidarr**: http://lidarr.theblacklodge.dev (Music)
- **Prowlarr**: http://prowlarr.theblacklodge.dev (Indexers)
- **Overseerr**: http://overseerr.theblacklodge.dev (Requests)
- **qBittorrent**: http://qbittorrent.theblacklodge.dev (Downloads)

### Data Lakehouse
- **MinIO**: http://minio-console.theblacklodge.dev (Object Storage)
- **Nessie**: http://nessie.theblacklodge.dev:19120 (Data Catalog)
- **Dremio**: http://dremio.theblacklodge.dev (Query Engine)
- **Airbyte**: http://airbyte.theblacklodge.dev (Data Integration)
- **Spark**: http://spark.theblacklodge.dev (Data Processing)
- **JupyterHub**: http://jupyter.theblacklodge.dev (Notebooks)
- **MLflow**: http://mlflow.theblacklodge.dev (ML Tracking)
- **Superset**: http://superset.theblacklodge.dev (Analytics)

### Development & Tools
- **Gitea**: http://gitea.theblacklodge.dev (Git Repos)
- **n8n**: http://n8n.theblacklodge.dev (Automation)
- **Vaultwarden**: http://vaultwarden.theblacklodge.dev (Passwords)
- **pgAdmin**: http://pgadmin.theblacklodge.dev (Database)
- **Grafana**: http://grafana.theblacklodge.dev (Monitoring)

---

## 🎬 Media Management Stack

### Overview

Your media stack automates the entire process of finding, downloading, organizing, and serving media content.

### Architecture Flow

```
User Request → Overseerr → Radarr/Sonarr/Lidarr → Prowlarr → Indexers
                                ↓
                          qBittorrent Downloads
                                ↓
                          Automatic Organization
                                ↓
                          NAS Storage (/volume1/media)
```

### 1. Overseerr - Request Management

**Purpose**: User-friendly interface for requesting movies, TV shows, and managing media.

**First-Time Setup**:
1. Visit http://overseerr.theblacklodge.dev
2. Sign in with Plex (or create local account)
3. Connect to Radarr:
   - URL: `http://radarr.apps.svc.cluster.local:7878`
   - API Key: Get from Radarr → Settings → General
4. Connect to Sonarr:
   - URL: `http://sonarr.apps.svc.cluster.local:8989`
   - API Key: Get from Sonarr → Settings → General

**How to Use**:
1. Search for a movie or TV show
2. Click "Request"
3. Overseerr sends request to Radarr/Sonarr
4. Automatic download and organization begins
5. Get notified when available

### 2. Prowlarr - Indexer Manager

**Purpose**: Central management for all torrent/usenet indexers.

**First-Time Setup**:
1. Visit http://prowlarr.theblacklodge.dev
2. Add indexers: Settings → Indexers → Add Indexer
   - Popular free options: 1337x, RARBG, The Pirate Bay
   - Private trackers if you have access
3. Connect apps: Settings → Apps → Add Application
   - Add Radarr, Sonarr, Lidarr with their API keys

**How to Use**:
- Prowlarr automatically syncs indexers to all connected apps
- Test indexers: Indexers → Test All
- Search across all indexers: Search tab

### 3. Radarr - Movie Management

**Purpose**: Automated movie collection management.

**First-Time Setup**:
1. Visit http://radarr.theblacklodge.dev
2. Settings → Media Management:
   - Root Folder: `/media/Movies`
   - File naming: Enable rename movies
3. Settings → Download Clients:
   - Add qBittorrent:
     - Host: `qbittorrent.apps.svc.cluster.local`
     - Port: `8080`
     - Username: `admin`
     - Category: `radarr`
4. Settings → Indexers:
   - Automatically populated by Prowlarr

**How to Use**:
1. Add movies: Movies → Add New
2. Search and select movie
3. Choose quality profile (e.g., HD-1080p)
4. Monitor: Yes
5. Search on add: Yes
6. Radarr will automatically download and organize

**Quality Profiles**:
- **Any**: Grabs first available
- **HD-720p/1080p**: High definition
- **Ultra-HD**: 4K content

### 4. Sonarr - TV Show Management

**Purpose**: Automated TV show collection management.

**Setup**: Same as Radarr but for TV shows
- Root folder: `/media/TV`
- Category in qBittorrent: `sonarr`

**How to Use**:
1. Add series: Series → Add New
2. Choose monitoring options:
   - All episodes
   - Future episodes
   - Missing episodes
   - First season
3. Sonarr monitors for new episodes automatically
4. Downloads and organizes by season

**Season Packs**: Sonarr can grab entire seasons if available

### 5. Lidarr - Music Management

**Purpose**: Automated music collection management.

**Setup**: Similar to Radarr/Sonarr
- Root folder: `/media/Music`
- Category: `lidarr`

**How to Use**:
1. Add artists: Artists → Add New
2. Choose monitoring:
   - All albums
   - Future albums
   - Missing albums
3. Automatic organization by Artist/Album

### 6. qBittorrent - Download Client

**Purpose**: Handles all torrent downloads.

**First-Time Setup**:
1. Visit http://qbittorrent.theblacklodge.dev
2. Login with default credentials (see CREDENTIALS.md)
3. **IMPORTANT**: Change password immediately
4. Settings → Downloads:
   - Default Save Path: `/media/Downloads`
   - Keep incomplete torrents in: `/media/Downloads/incomplete`
5. Settings → BitTorrent:
   - Enable DHT, PeX, LPD
   - Max active downloads: 3-5

**Categories** (auto-created by apps):
- `radarr`: Movie downloads
- `sonarr`: TV downloads
- `lidarr`: Music downloads

**Monitoring**:
- Check download progress
- View upload/download speeds
- Manage seeding ratios

---

## 🏗️ Data Lakehouse Platform

### What is a Data Lakehouse?

A data lakehouse combines the best of data lakes (flexible storage) and data warehouses (structured analytics). Your platform enables:
- **Storage**: MinIO (S3-compatible object storage)
- **Catalog**: Nessie (version-controlled data catalog)
- **Query**: Dremio (SQL query engine)
- **Integration**: Airbyte (data ingestion)
- **Processing**: Spark (distributed computing)
- **ML**: MLflow (experiment tracking) + JupyterHub (notebooks)
- **Analytics**: Superset (dashboards and visualization)

### Architecture

```
Data Sources → Airbyte → MinIO (Raw Data)
                            ↓
                    Nessie (Catalog)
                            ↓
                    Spark (Processing)
                            ↓
                    MinIO (Processed Data)
                            ↓
                    Dremio (Query Layer)
                            ↓
              Superset (Visualization)
              
ML Workflow: JupyterHub → MLflow → Model Registry
```

### 1. MinIO - Object Storage (S3-Compatible)

**Purpose**: Foundation of your data lake - stores all raw and processed data.

**Access**:
- Console: http://minio-console.theblacklodge.dev
- API: http://minio.theblacklodge.dev
- Access Key: `7t2BEhZXXbQCnfyvQrZW`
- Secret Key: `m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw`

**First-Time Setup**:
1. Login to MinIO Console
2. Create buckets:
   ```
   - raw-data          # Raw ingested data
   - processed-data    # Cleaned/transformed data
   - ml-artifacts      # ML models and artifacts
   - lakehouse         # Iceberg tables
   ```
3. Set bucket policies (Public/Private)
4. Create access keys for applications

**Using MinIO**:

**Via Console**:
- Upload files through web interface
- Browse buckets and objects
- Set retention policies
- Monitor storage usage

**Via Python (boto3)**:
```python
import boto3

s3 = boto3.client('s3',
    endpoint_url='http://minio.theblacklodge.dev',
    aws_access_key_id='7t2BEhZXXbQCnfyvQrZW',
    aws_secret_access_key='m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw'
)

# Upload file
s3.upload_file('local_file.csv', 'raw-data', 'data/file.csv')

# Download file
s3.download_file('raw-data', 'data/file.csv', 'local_file.csv')

# List objects
response = s3.list_objects_v2(Bucket='raw-data', Prefix='data/')
for obj in response.get('Contents', []):
    print(obj['Key'])
```

**Via AWS CLI**:
```bash
# Configure
aws configure set aws_access_key_id 7t2BEhZXXbQCnfyvQrZW
aws configure set aws_secret_access_key m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw

# Upload
aws s3 cp file.csv s3://raw-data/data/ --endpoint-url http://minio.theblacklodge.dev

# List
aws s3 ls s3://raw-data/ --endpoint-url http://minio.theblacklodge.dev
```

### 2. Nessie - Data Catalog

**Purpose**: Version control for your data lake (like Git for data).

**Access**:
- API: http://nessie.theblacklodge.dev:19120
- No authentication by default

**Concepts**:
- **Branch**: Isolated environment for data changes
- **Tag**: Named snapshot of data state
- **Commit**: Record of data changes
- **Table**: Iceberg table reference

**Using Nessie**:

**Via Python**:
```python
from pynessie import init

# Connect to Nessie
client = init('http://nessie.theblacklodge.dev:19120')

# List branches
branches = client.list_references()
for branch in branches:
    print(f"Branch: {branch.name}")

# Create branch
client.create_branch('dev', 'main')

# List tables
tables = client.list_entries('main')
for table in tables:
    print(f"Table: {table.name}")
```

**Best Practices**:
- Use `main` branch for production data
- Create `dev` branches for experimentation
- Tag releases for reproducibility
- Commit with meaningful messages

### 3. Dremio - SQL Query Engine

**Purpose**: Fast SQL queries across your data lake without moving data.

**Access**: http://dremio.theblacklodge.dev
- Username: `admin`
- Password: `Dremio123!`

**First-Time Setup**:

1. **Add MinIO as Source**:
   - Sources → Add Source → Amazon S3
   - Name: `minio`
   - Authentication: AWS Access Key
   - Access Key: `7t2BEhZXXbQCnfyvQrZW`
   - Secret Key: `m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw`
   - Root Path: `/`
   - Connection Properties:
     - `fs.s3a.endpoint`: `minio.datalake.svc.cluster.local:9000`
     - `fs.s3a.path.style.access`: `true`
     - `dremio.s3.compat`: `true`

2. **Add Nessie as Source**:
   - Sources → Add Source → Nessie
   - Name: `nessie`
   - Endpoint URL: `http://nessie.datalake.svc.cluster.local:19120/api/v1`
   - Authentication: None
   - Storage: Use existing MinIO source

3. **Create Spaces**:
   - Spaces → Add Space → Name: `analytics`
   - This is where you'll create views and virtual datasets

**Using Dremio**:

**Query Data**:
```sql
-- Query CSV in MinIO
SELECT * FROM minio."raw-data".data."file.csv" LIMIT 10;

-- Query Iceberg table via Nessie
SELECT * FROM nessie.main.customer_data LIMIT 10;

-- Create virtual dataset
CREATE VDS analytics.customer_summary AS
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(amount) as total_spent
FROM nessie.main.orders
GROUP BY customer_id;

-- Join across sources
SELECT 
    c.name,
    o.order_date,
    o.amount
FROM nessie.main.customers c
JOIN nessie.main.orders o ON c.id = o.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '30' DAY;
```

**Reflections** (Acceleration):
- Dremio can create materialized views for faster queries
- Settings → Reflections → Enable for frequently queried datasets

### 4. Airbyte - Data Integration

**Purpose**: Extract data from various sources and load into your data lake.

**Access**: http://airbyte.theblacklodge.dev
- Username: `airbyte`
- Password: `password`

**First-Time Setup**:

1. **Configure Destination (MinIO)**:
   - Destinations → New Destination → S3
   - Name: `MinIO Data Lake`
   - S3 Bucket Name: `raw-data`
   - S3 Bucket Path: `airbyte`
   - S3 Endpoint: `http://minio.datalake.svc.cluster.local:9000`
   - Access Key ID: `7t2BEhZXXbQCnfyvQrZW`
   - Secret Access Key: `m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw`
   - Format: JSON Lines or Parquet

2. **Add Sources** (examples):
   - **PostgreSQL**: Your own databases
   - **REST API**: Any API endpoint
   - **CSV/File**: Upload or URL
   - **Google Sheets**: Spreadsheet data
   - **GitHub**: Repository data
   - **Stripe**: Payment data
   - **MySQL**: Database replication

**Common Source Examples**:

**PostgreSQL Source**:
```
Host: your-db-host
Port: 5432
Database: your_database
Username: readonly_user
Password: ********
Replication Method: CDC (Change Data Capture) or Full Refresh
```

**REST API Source**:
```
URL: https://api.example.com/data
Authentication: API Key / Bearer Token
Pagination: Link / Offset
```

**Creating a Connection**:
1. Sources → New Source → Select connector
2. Configure source credentials
3. Test connection
4. Connections → New Connection
5. Select source and destination
6. Choose sync mode:
   - **Full Refresh**: Replace all data
   - **Incremental**: Only new/changed data
7. Select streams (tables/endpoints)
8. Set sync frequency (hourly, daily, manual)

**Monitoring**:
- View sync history
- Check for errors
- Monitor data volume
- Set up alerts

### 5. Apache Spark - Data Processing

**Purpose**: Distributed data processing for transformations and analytics.

**Access**: http://spark.theblacklodge.dev

**Using Spark from JupyterHub**:

```python
from pyspark.sql import SparkSession

# Create Spark session
spark = SparkSession.builder \
    .appName("DataProcessing") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio.datalake.svc.cluster.local:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "7t2BEhZXXbQCnfyvQrZW") \
    .config("spark.hadoop.fs.s3a.secret.key", "m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Read data from MinIO
df = spark.read.parquet("s3a://raw-data/data/")

# Transform data
df_clean = df.filter(df.value > 0) \
    .withColumn("processed_date", current_date()) \
    .groupBy("category") \
    .agg({"value": "sum"})

# Write back to MinIO
df_clean.write.mode("overwrite") \
    .parquet("s3a://processed-data/aggregated/")

spark.stop()
```

**Common Transformations**:
```python
# Data cleaning
df_clean = df.dropna()  # Remove nulls
df_clean = df.dropDuplicates()  # Remove duplicates

# Aggregations
df_agg = df.groupBy("category").agg(
    count("*").alias("count"),
    avg("value").alias("avg_value"),
    sum("value").alias("total")
)

# Joins
df_joined = df1.join(df2, df1.id == df2.id, "left")

# Window functions
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number

window = Window.partitionBy("category").orderBy(desc("value"))
df_ranked = df.withColumn("rank", row_number().over(window))
```

### 6. JupyterHub - Interactive Notebooks

**Purpose**: Interactive Python environment for data science and ML.

**Access**: http://jupyter.theblacklodge.dev

**First-Time Setup**:
1. Create user account
2. Start server
3. Create new notebook

**Pre-installed Libraries**:
- pandas, numpy, scipy
- matplotlib, seaborn, plotly
- scikit-learn, tensorflow, pytorch
- pyspark
- boto3 (for MinIO)
- mlflow

**Example Notebook**:

```python
# Cell 1: Setup
import pandas as pd
import boto3
import matplotlib.pyplot as plt
from io import BytesIO

# MinIO client
s3 = boto3.client('s3',
    endpoint_url='http://minio.datalake.svc.cluster.local:9000',
    aws_access_key_id='7t2BEhZXXbQCnfyvQrZW',
    aws_secret_access_key='m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw'
)

# Cell 2: Load data
obj = s3.get_object(Bucket='raw-data', Key='data/sales.csv')
df = pd.read_csv(BytesIO(obj['Body'].read()))

# Cell 3: Explore
print(df.head())
print(df.describe())
print(df.info())

# Cell 4: Visualize
df.groupby('category')['sales'].sum().plot(kind='bar')
plt.title('Sales by Category')
plt.show()

# Cell 5: Save results
result_csv = df.groupby('category').agg({'sales': 'sum'}).to_csv()
s3.put_object(
    Bucket='processed-data',
    Key='analysis/category_sales.csv',
    Body=result_csv
)
```

### 7. MLflow - ML Experiment Tracking

**Purpose**: Track machine learning experiments, models, and metrics.

**Access**: http://mlflow.theblacklodge.dev

**Using MLflow**:

```python
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Set tracking URI
mlflow.set_tracking_uri("http://mlflow.datalake.svc.cluster.local:5000")

# Create experiment
mlflow.set_experiment("customer-churn-prediction")

# Start run
with mlflow.start_run(run_name="random-forest-v1"):
    # Log parameters
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)
    
    # Train model
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
    model = RandomForestClassifier(n_estimators=100, max_depth=10)
    model.fit(X_train, y_train)
    
    # Evaluate
    predictions = model.predict(X_test)
    accuracy = accuracy_score(y_test, predictions)
    
    # Log metrics
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("test_samples", len(X_test))
    
    # Log model
    mlflow.sklearn.log_model(model, "model")
    
    # Log artifacts
    plt.figure()
    feature_importance = pd.DataFrame({
        'feature': X.columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    feature_importance.plot(x='feature', y='importance', kind='bar')
    plt.savefig("feature_importance.png")
    mlflow.log_artifact("feature_importance.png")
```

**MLflow UI Features**:
- Compare experiments
- View metrics over time
- Download models
- Register models for production
- Track model lineage

### 8. Superset - Data Visualization

**Purpose**: Create dashboards and visualizations from your data.

**Access**: http://superset.theblacklodge.dev
- Username: `admin`
- Password: `admin`

**First-Time Setup**:

1. **Add Database Connection (Dremio)**:
   - Settings → Database Connections → + Database
   - Select: Other
   - Display Name: `Dremio`
   - SQLAlchemy URI: `dremio://admin:Dremio123!@dremio.datalake.svc.cluster.local:31010/`
   - Test Connection
   - Save

2. **Add Datasets**:
   - Data → Datasets → + Dataset
   - Select database: Dremio
   - Select schema: nessie.main or analytics
   - Select table
   - Add

3. **Create Chart**:
   - Charts → + Chart
   - Choose dataset
   - Choose visualization type:
     - Time Series (line/bar)
     - Pie Chart
     - Table
     - Big Number
     - Heatmap
     - Scatter Plot
   - Configure metrics and dimensions
   - Save

4. **Create Dashboard**:
   - Dashboards → + Dashboard
   - Drag and drop charts
   - Add filters
   - Arrange layout
   - Publish

**Example Chart Types**:

**Sales Over Time**:
- Visualization: Time Series Bar Chart
- Time Column: order_date
- Metrics: SUM(amount)
- Group by: category

**Customer Distribution**:
- Visualization: Pie Chart
- Dimension: customer_segment
- Metric: COUNT(DISTINCT customer_id)

**Top Products**:
- Visualization: Table
- Columns: product_name, category
- Metrics: SUM(quantity), SUM(revenue)
- Sort by: revenue DESC
- Limit: 10

---

## 🔄 Complete Data Lakehouse Workflows

### Workflow 1: Public Dataset Analysis

**Goal**: Analyze COVID-19 data and create dashboards

**Step 1: Get Data**
```bash
# Download COVID-19 dataset
wget https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv
```

**Step 2: Upload to MinIO**
```python
import boto3

s3 = boto3.client('s3',
    endpoint_url='http://minio.theblacklodge.dev',
    aws_access_key_id='7t2BEhZXXbQCnfyvQrZW',
    aws_secret_access_key='m1NIJiY1ws3409BmauDbyVx7TEjedn7puza7StUw'
)

s3.upload_file('owid-covid-data.csv', 'raw-data', 'covid/owid-covid-data.csv')
```

**Step 3: Process with Spark (in JupyterHub)**
```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

spark = SparkSession.builder.appName("COVID Analysis").getOrCreate()

# Read data
df = spark.read.option("header", "true").csv("s3a://raw-data/covid/owid-covid-data.csv")

# Clean and transform
df_clean = df.filter(col("location").isNotNull()) \
    .withColumn("date", to_date(col("date"))) \
    .withColumn("new_cases", col("new_cases").cast("double")) \
    .withColumn("total_deaths", col("total_deaths").cast("double"))

# Aggregate by country
df_summary = df_clean.groupBy("location", "continent") \
    .agg(
        max("total_cases").alias("total_cases"),
        max("total_deaths").alias("total_deaths"),
        avg("new_cases").alias("avg_daily_cases")
    )

# Save processed data
df_summary.write.mode("overwrite") \
    .parquet("s3a://processed-data/covid/country_summary/")
```

**Step 4: Query in Dremio**
```sql
-- Create view
CREATE VDS analytics.covid_summary AS
SELECT 
    location as country,
    continent,
    total_cases,
    total_deaths,
    CAST(total_deaths AS DOUBLE) / CAST(total_cases AS DOUBLE) * 100 as mortality_rate,
    avg_daily_cases
FROM minio."processed-data".covid.country_summary
WHERE continent IS NOT NULL
ORDER BY total_cases DESC;

-- Analyze trends
SELECT 
    continent,
    SUM(total_cases) as total_cases,
    SUM(total_deaths) as total_deaths,
    AVG(mortality_rate) as avg_mortality_rate
FROM analytics.covid_summary
GROUP BY continent
ORDER BY total_cases DESC;
```

**Step 5: Visualize in Superset**
1. Add dataset: `analytics.covid_summary`
2. Create charts:
   - **World Map**: Cases by country
   - **Bar Chart**: Top 20 countries by cases
   - **Line Chart**: Cases over time
   - **Pie Chart**: Cases by continent
3. Create dashboard: "COVID-19 Global Analysis"

### Workflow 2: API Data Pipeline

**Goal**: Ingest data from a REST API, process it, and create real-time dashboards

**Step 1: Setup Airbyte Connection**
1. Source: REST API (e.g., OpenWeather API)
   - URL: `https://api.openweathermap.org/data/2.5/weather`
   - Parameters: `?q=London&appid=YOUR_API_KEY`
2. Destination: MinIO (`raw-data/weather/`)
3. Schedule: Every hour

**Step 2: Process with Spark**
```python
# Read latest weather data
df = spark.read.json("s3a://raw-data/weather/*.json")

# Extract relevant fields
df_weather = df.select(
    col("name").alias("city"),
    col("sys.country").alias("country"),
    col("main.temp").alias("temperature"),
    col("main.humidity").alias("humidity"),
    col("weather")[0]["description"].alias("conditions"),
    from_unixtime(col("dt")).alias("timestamp")
)

# Convert Kelvin to Celsius
df_weather = df_weather.withColumn(
    "temp_celsius",
    round(col("temperature") - 273.15, 2)
)

# Save
df_weather.write.mode("append") \
    .partitionBy("country") \
    .parquet("s3a://processed-data/weather/hourly/")
```

**Step 3: Create Dremio View**
```sql
CREATE VDS analytics.weather_current AS
SELECT 
    city,
    country,
    temp_celsius as temperature,
    humidity,
    conditions,
    timestamp
FROM minio."processed-data".weather.hourly
WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR;
```

**Step 4: Superset Dashboard**
- Real-time temperature map
- Humidity trends
- Weather conditions distribution

### Workflow 3: Machine Learning Pipeline

**Goal**: Train a model, track experiments, deploy predictions

**Step 1: Prepare Data (JupyterHub)**
```python
import pandas as pd
import mlflow
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import classification_report, roc_auc_score

# Load data from MinIO
df = pd.read_parquet("s3a://processed-data/customer_data/")

# Feature engineering
X = df[['age', 'income', 'tenure', 'num_products']]
y = df['churned']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
```

**Step 2: Train and Track (MLflow)**
```python
mlflow.set_tracking_uri("http://mlflow.datalake.svc.cluster.local:5000")
mlflow.set_experiment("churn-prediction")

with mlflow.start_run():
    # Train
    model = GradientBoostingClassifier(n_estimators=100, learning_rate=0.1)
    model.fit(X_train, y_train)
    
    # Evaluate
    predictions = model.predict(X_test)
    auc = roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
    
    # Log
    mlflow.log_params(model.get_params())
    mlflow.log_metric("auc", auc)
    mlflow.sklearn.log_model(model, "model")
```

**Step 3: Generate Predictions**
```python
# Load best model
model_uri = "runs:/<run_id>/model"
model = mlflow.sklearn.load_model(model_uri)

# Score all customers
df['churn_probability'] = model.predict_proba(X)[:, 1]
df['churn_prediction'] = model.predict(X)

# Save predictions
df.to_parquet("s3a://processed-data/predictions/churn_scores.parquet")
```

**Step 4: Visualize Results (Superset)**
- Churn probability distribution
- High-risk customer segments
- Feature importance chart
- Model performance metrics

### Workflow 4: Data Quality Monitoring

**Goal**: Monitor data quality and freshness

**Step 1: Create Quality Checks (Spark)**
```python
def check_data_quality(df, table_name):
    checks = {
        'row_count': df.count(),
        'null_counts': {col: df.filter(df[col].isNull()).count() 
                       for col in df.columns},
        'duplicates': df.count() - df.dropDuplicates().count(),
        'latest_date': df.agg(max('date')).collect()[0][0]
    }
    
    # Save quality metrics
    quality_df = spark.createDataFrame([{
        'table_name': table_name,
        'check_timestamp': datetime.now(),
        **checks
    }])
    
    quality_df.write.mode("append") \
        .parquet("s3a://processed-data/quality/metrics/")
    
    return checks

# Run checks
quality_results = check_data_quality(df, "customer_data")
```

**Step 2: Create Quality Dashboard (Superset)**
- Data freshness by table
- Null value trends
- Row count trends
- Data quality score

---

## 💡 Project Ideas & Use Cases

### Beginner Projects

#### 1. Personal Finance Tracker
**Data Sources**:
- Bank statements (CSV upload)
- Manual expense entry via Google Sheets
- Airbyte: Google Sheets → MinIO

**Processing**:
- Categorize transactions
- Calculate monthly trends
- Identify spending patterns

**Visualization**:
- Monthly spending by category
- Income vs expenses
- Savings rate over time
- Budget vs actual

#### 2. Weather Analysis
**Data Sources**:
- OpenWeather API (via Airbyte)
- Historical weather data (CSV)

**Processing**:
- Temperature trends
- Precipitation patterns
- Seasonal analysis

**Visualization**:
- Temperature heatmap
- Rainfall patterns
- Weather forecast accuracy

#### 3. Movie/TV Show Tracker
**Data Sources**:
- Your Radarr/Sonarr databases
- TMDB API (via Airbyte)

**Processing**:
- Collection statistics
- Genre distribution
- Watch history analysis

**Visualization**:
- Collection growth over time
- Genre preferences
- Storage usage
- Quality distribution

### Intermediate Projects

#### 4. Social Media Analytics
**Data Sources**:
- Twitter API (via Airbyte)
- Reddit API
- YouTube API

**Processing**:
- Sentiment analysis
- Trending topics
- Engagement metrics

**Visualization**:
- Sentiment trends
- Top posts/tweets
- Engagement rates
- Hashtag analysis

**ML Component**:
- Sentiment classification
- Topic modeling
- Engagement prediction

#### 5. Stock Market Analysis
**Data Sources**:
- Yahoo Finance API
- Alpha Vantage API
- News APIs

**Processing**:
- Price trends
- Volume analysis
- Technical indicators
- News sentiment

**Visualization**:
- Stock price charts
- Portfolio performance
- Correlation matrix
- Risk metrics

**ML Component**:
- Price prediction
- Anomaly detection
- Portfolio optimization

#### 6. Home Energy Monitoring
**Data Sources**:
- Smart home devices
- Utility bills
- Weather data

**Processing**:
- Energy consumption patterns
- Cost analysis
- Efficiency metrics

**Visualization**:
- Daily/monthly usage
- Cost trends
- Device breakdown
- Weather correlation

### Advanced Projects

#### 7. Customer 360 Platform
**Data Sources**:
- CRM data (Salesforce/HubSpot via Airbyte)
- Transaction data
- Support tickets
- Web analytics

**Processing**:
- Customer segmentation
- Lifetime value calculation
- Churn prediction
- Behavior analysis

**Visualization**:
- Customer journey maps
- Segment performance
- Churn risk dashboard
- Revenue attribution

**ML Component**:
- Churn prediction model
- Next best action
- Customer scoring
- Recommendation engine

#### 8. IoT Sensor Data Platform
**Data Sources**:
- IoT devices (MQTT)
- Sensor readings
- Device metadata

**Processing**:
- Time series aggregation
- Anomaly detection
- Predictive maintenance

**Visualization**:
- Real-time sensor readings
- Alert dashboard
- Device health
- Maintenance schedule

**ML Component**:
- Failure prediction
- Anomaly detection
- Pattern recognition

#### 9. Content Recommendation System
**Data Sources**:
- User behavior data
- Content metadata
- Engagement metrics

**Processing**:
- User profiling
- Content similarity
- Collaborative filtering

**Visualization**:
- User segments
- Content performance
- Recommendation accuracy
- A/B test results

**ML Component**:
- Recommendation model
- Content embedding
- User clustering

### Data Sources to Explore

#### Free Public Datasets

1. **Government Data**:
   - data.gov (US Government)
   - data.gov.uk (UK Government)
   - Census data
   - Economic indicators

2. **Academic Datasets**:
   - UCI Machine Learning Repository
   - Kaggle Datasets
   - Google Dataset Search
   - Papers with Code

3. **APIs**:
   - OpenWeather (weather)
   - NewsAPI (news articles)
   - GitHub API (code statistics)
   - Reddit API (social data)
   - Twitter API (social media)
   - Alpha Vantage (financial)

4. **Specialized**:
   - COVID-19 data (Our World in Data)
   - Sports data (sports-reference.com)
   - Movie data (TMDB, OMDB)
   - Music data (Spotify API, Last.fm)

#### Setting Up Data Ingestion

**Example: GitHub API via Airbyte**
1. Airbyte → Sources → GitHub
2. Repository: `owner/repo`
3. Access Token: Generate from GitHub
4. Streams: commits, issues, pull_requests
5. Destination: MinIO
6. Schedule: Daily

**Example: Google Sheets**
1. Create Google Sheet with data
2. Airbyte → Sources → Google Sheets
3. Authenticate with Google
4. Select spreadsheet
5. Destination: MinIO
6. Schedule: Hourly

---

## 🛠️ Development & Automation

### Gitea - Git Repository Hosting

**Purpose**: Self-hosted Git for your code and notebooks.

**First-Time Setup**:
1. Visit http://gitea.theblacklodge.dev
2. Complete installation wizard
3. Create admin account
4. Configure:
   - Database: PostgreSQL (already configured)
   - Repository root: `/data/gitea-repositories`

**Using Gitea**:
```bash
# Clone repository
git clone http://gitea.theblacklodge.dev/username/repo.git

# Add remote
git remote add homelab http://gitea.theblacklodge.dev/username/repo.git

# Push code
git push homelab main
```

**Use Cases**:
- Store Jupyter notebooks
- Version control Spark jobs
- Share SQL queries
- Document data pipelines
- Collaborate on ML models

### n8n - Workflow Automation

**Purpose**: Automate tasks and create workflows without code.

**First-Time Setup**:
1. Visit http://n8n.theblacklodge.dev
2. Create owner account
3. Database: PostgreSQL (auto-configured)

**Example Workflows**:

**1. Data Quality Alerts**:
```
Trigger: Webhook (from Spark job)
→ Filter: If error_count > threshold
→ Slack: Send alert
→ Email: Notify team
```

**2. Automated Reports**:
```
Trigger: Schedule (daily at 9 AM)
→ HTTP Request: Query Dremio API
→ Spreadsheet: Update Google Sheets
→ Email: Send report
```

**3. ML Model Deployment**:
```
Trigger: Webhook (from MLflow)
→ HTTP Request: Get model metadata
→ Slack: Notify team
→ HTTP Request: Deploy to production
```

**4. Data Pipeline Orchestration**:
```
Trigger: Schedule (hourly)
→ HTTP Request: Trigger Airbyte sync
→ Wait: 30 minutes
→ HTTP Request: Run Spark job
→ HTTP Request: Refresh Superset cache
```

### Vaultwarden - Password Manager

**Purpose**: Secure password storage for all your credentials.

**Setup**:
1. Visit http://vaultwarden.theblacklodge.dev
2. Create account
3. Install browser extension
4. Store credentials:
   - MinIO keys
   - API tokens
   - Database passwords
   - Service credentials

**Organization**:
- Create folders: "Data Platform", "Media Apps", "Development"
- Use secure notes for API keys
- Share credentials with team (if applicable)

---

## 📊 Monitoring & Management

### Grafana - Metrics & Dashboards

**Purpose**: Monitor infrastructure and application metrics.

**Access**: http://grafana.theblacklodge.dev
- Username: `admin`
- Password: `admin123`

**Pre-configured Dashboards**:
- Kubernetes cluster metrics
- Node resource usage
- Pod performance
- Storage utilization

**Custom Dashboards**:
- Data pipeline metrics
- ML model performance
- Query performance
- Data freshness

### pgAdmin - Database Management

**Purpose**: Manage PostgreSQL databases.

**Access**: http://pgadmin.theblacklodge.dev
- Email: `admin@theblacklodge.dev`
- Password: `admin123`

**Add Server**:
1. Right-click Servers → Create → Server
2. General tab:
   - Name: `Homelab PostgreSQL`
3. Connection tab:
   - Host: `postgresql.core.svc.cluster.local`
   - Port: `5432`
   - Username: `postgres`
   - Password: `postgres123`

**Common Tasks**:
- View database schemas
- Run SQL queries
- Backup databases
- Monitor connections
- Analyze query performance

---

## 🎓 Learning Path

### Week 1: Basics
- [ ] Upload CSV to MinIO
- [ ] Query data in Dremio
- [ ] Create simple chart in Superset
- [ ] Run Jupyter notebook

### Week 2: Data Integration
- [ ] Set up Airbyte source
- [ ] Create scheduled sync
- [ ] Process data with Spark
- [ ] Create Dremio view

### Week 3: Analytics
- [ ] Build Superset dashboard
- [ ] Create calculated fields
- [ ] Add filters and drill-downs
- [ ] Share dashboard

### Week 4: Machine Learning
- [ ] Train model in Jupyter
- [ ] Track with MLflow
- [ ] Generate predictions
- [ ] Visualize results

### Week 5: Automation
- [ ] Create n8n workflow
- [ ] Schedule data pipeline
- [ ] Set up alerts
- [ ] Monitor with Grafana

---

## 📚 Additional Resources

### Documentation
- **MinIO**: https://min.io/docs/minio/linux/index.html
- **Nessie**: https://projectnessie.org/
- **Dremio**: https://docs.dremio.com/
- **Airbyte**: https://docs.airbyte.com/
- **Spark**: https://spark.apache.org/docs/latest/
- **MLflow**: https://mlflow.org/docs/latest/index.html
- **Superset**: https://superset.apache.org/docs/intro

### Tutorials
- Apache Iceberg: https://iceberg.apache.org/docs/latest/
- Data Lakehouse: https://www.databricks.com/glossary/data-lakehouse
- Modern Data Stack: https://www.moderndatastack.xyz/

### Community
- r/dataengineering
- r/datascience
- r/selfhosted
- r/homelab

---

## 🆘 Getting Help

### Troubleshooting

**Application won't start**:
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Can't connect to service**:
```bash
kubectl get svc -n <namespace>
kubectl get ingress -n <namespace>
```

**Storage issues**:
```bash
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc-name> -n <namespace>
```

### Support Channels
- Check application logs
- Review Grafana metrics
- Consult official documentation
- Search community forums

---

**Happy Data Engineering! 🚀**

