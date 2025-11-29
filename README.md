# Monitoring Stack

A production-ready monitoring stack with Prometheus, Grafana, and Jaeger v2 distributed tracing, running in Docker containers with persistent storage and backup capabilities.

## 🏗️ Architecture

```
┌──────────────┐     ┌──────────────┐     ┌─────────────────────────┐
│  Prometheus  │     │   Grafana    │     │      Jaeger v2          │
│   :9090      │────▶│    :9999     │◀────│   (All-in-one)          │
└──────────────┘     └──────────────┘     │  UI: :16686             │
                                          │  OTLP: :4317, :4318     │
                                          │  Jaeger: :14250, :14268 │
                                          │  Zipkin: :9411          │
                                          └────────────┬────────────┘
                                                       │
                                          ┌────────────▼────────────┐
                                          │   Elasticsearch         │
                                          │      :9200              │
                                          │                         │
                                          │  Persistent Storage     │
                                          │  + Backup Snapshots     │
                                          └─────────────────────────┘
```

## 📦 Components

### Prometheus
- **Port**: 9090
- **Purpose**: Metrics collection and time-series database
- **Storage**: `./backup/prometheus_data`

### Grafana
- **Port**: 3000
- **Purpose**: Visualization and dashboards
- **Storage**: `./backup/grafana_data`
- **Default Credentials**: admin/admin

### Jaeger v2 (Distributed Tracing)
- **UI Port**: 16686
- **OTLP Ports**: 4317 (gRPC), 4318 (HTTP)
- **Jaeger Native Ports**: 14250 (gRPC), 14268 (HTTP)
- **Zipkin Compatible Port**: 9411
- **Purpose**: Distributed tracing and performance monitoring (OpenTelemetry-based)
- **Storage**: Elasticsearch with persistent backup

### Elasticsearch
- **Port**: 9200
- **Purpose**: Persistent storage for Jaeger traces
- **Storage**: 
  - Live data: `./backup/es_data`
  - Snapshots: `./backup/es_snapshots`

## 🚀 Quick Start

### 1. Start the Stack

```bash
# Start all services
docker-compose up -d

# Verify all services are running
docker-compose ps

# Check logs
docker-compose logs -f
```

### 2. Access the Services

- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Jaeger UI**: http://localhost:16686
- **Elasticsearch**: http://localhost:9200

## 📊 Features

### ✅ Persistent Storage
- All data persists across container restarts
- Elasticsearch provides durable storage for traces
- Automatic volume mounting for data persistence

### ✅ Backup & Restore
- Native Elasticsearch snapshot capabilities
- Automated backup scripts included
- Point-in-time recovery support
- See [Backup Guide](./tools/jaeger/BACKUP_GUIDE.md) for details

### ✅ Health Checks
- Elasticsearch health monitoring
- Service dependencies properly configured
- Auto-restart on failure

### ✅ Production-Ready
- Jaeger v2 (OpenTelemetry-based) all-in-one deployment
- Resource limits configured for all services
- Health checks and auto-restart policies
- Proper logging and monitoring

## 💾 Data Persistence

All service data is persisted in the `./backup` directory:

```
backup/
├── es_data/              # Elasticsearch live data (Jaeger traces)
├── es_snapshots/         # Elasticsearch snapshot repository
├── prometheus_data/      # Prometheus time-series data
├── grafana_data/         # Grafana configuration and dashboards
└── grafana_provisioning/ # Grafana provisioning files
```

### Backup Strategy

To backup your data:
```bash
# Stop services
docker-compose down

# Backup the entire backup directory
tar -czf monitoring-backup-$(date +%Y%m%d).tar.gz backup/

# Restart services
docker-compose up -d
```

### Restore from Backup

```bash
# Stop services
docker-compose down

# Extract backup
tar -xzf monitoring-backup-YYYYMMDD.tar.gz

# Restart services
docker-compose up -d
```

## 🔧 Configuration

### Jaeger v2 Configuration

Jaeger v2 uses OpenTelemetry Collector-based configuration:
- **Config file**: `./tools/jaeger/jaeger.yaml`
- **Storage**: Elasticsearch backend (`some_storage`)
- **Receivers**: OTLP (gRPC/HTTP), Jaeger native, Zipkin
- **Processors**: Batch processing, memory limiter

Edit `./tools/jaeger/jaeger.yaml` to customize:
```yaml
extensions:
  jaeger_storage:
    backends:
      some_storage:
        elasticsearch:
          server_urls: 
            - http://elasticsearch:9200
```

### Prometheus Configuration

Edit `./tools/prometheus/prometheus.yml` for scrape targets.

### Grafana Configuration

Edit `./tools/grafana/grafana.ini` and datasources in `./tools/grafana/traditional-datasources.yaml`.

The Jaeger data source is pre-configured to connect to `http://jaeger:16686`.

### Elasticsearch Configuration

Modify in `docker-compose.yaml`:
- Memory: `ES_JAVA_OPTS=-Xms1g -Xmx1g` (default: 1GB)
- Snapshot path: Already configured in `path.repo`

## 📁 Directory Structure

```
monitoring-docker-setup/
├── docker-compose.yaml          # Main compose file
├── docker-compose-gpu.yaml      # GPU monitoring variant
├── README.md                    # This file
├── tools/
│   ├── prometheus/
│   │   └── prometheus.yml       # Prometheus config
│   ├── grafana/
│   │   ├── grafana.ini         # Grafana config
│   │   └── traditional-datasources.yaml
│   ├── elasticsearch/
│   │   └── elasticsearch.yml    # Elasticsearch config
│   └── jaeger/
│       └── jaeger.yaml          # Jaeger v2 config (OTEL Collector)
└── backup/
    ├── es_data/                # Elasticsearch data
    ├── es_snapshots/           # Elasticsearch snapshots
    ├── jaeger_archives/        # Backup archives
    ├── prometheus_data/        # Prometheus data
    ├── grafana_data/           # Grafana data
    └── grafana_provisioning/   # Grafana provisioning
```

## 🛠️ Operations

### Start Services

```bash
docker-compose up -d
```

### Stop Services

```bash
docker-compose down
```

### Restart a Service

```bash
docker-compose restart jaeger
# or
docker restart jaeger
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f jaeger
docker-compose logs -f elasticsearch
```

### Check Status

```bash
# Docker compose status
docker-compose ps

# Elasticsearch health
curl http://localhost:9200/_cluster/health?pretty

# Available snapshots
curl http://localhost:9200/_snapshot/jaeger_backup/_all?pretty
```

## 🔍 Monitoring Jaeger

### Check Trace Storage

```bash
# Count traces
curl "http://localhost:9200/jaeger-span-*/_count?pretty"

# List indices
curl "http://localhost:9200/_cat/indices/jaeger-*?v"

# View traces in UI
open http://localhost:16686
```

### Send Test Traces

You can use the Jaeger HotROD demo application:

```bash
docker run --rm --name hotrod \
  --network monitoring-docker-setup_monitoring \
  -p 8080:8080 \
  jaegertracing/example-hotrod:latest \
  all --otel-exporter=otlp --otlp-endpoint=http://jaeger:4318
```

Access HotROD at http://localhost:8080 and generate traces.

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger v2 Documentation](https://www.jaegertracing.io/docs/latest/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is open source and available under the MIT License.

---