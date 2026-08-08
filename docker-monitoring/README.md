# Docker Monitoring Stack

This project uses Docker Compose to run a simple monitoring stack for container metrics and system observability.

## Components

- Prometheus: collects and stores metrics
- Grafana: visualizes metrics in dashboards
- cAdvisor: exposes container and host metrics from Docker

## Services and ports

| Service | URL | Purpose |
| --- | --- | --- |
| Prometheus | http://localhost:9090 | Query and inspect collected metrics |
| Grafana | http://localhost:3000 | Dashboards and visualizations |
| cAdvisor | http://localhost:8081 | Container metrics endpoint |

## Project structure

```bash
.
├── docker-compose.yml
├── prometheus/
│   └── prometheus.yml
└── README.md
```

## Configuration overview

### Prometheus
The Prometheus configuration file is in `prometheus/prometheus.yml` and is set to scrape metrics every 5 seconds:

```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - prometheus:9090

  - job_name: "cadvisor"
    static_configs:
      - targets:
          - cadvisor:8080
```

This means Prometheus is configured to collect:
- its own metrics from `prometheus:9090`
- cAdvisor metrics from `cadvisor:8080`

### Grafana
Grafana runs on port `3000` and stores its data in the Docker volume `grafana-storage`.

### cAdvisor
cAdvisor is exposed on `8081`, while internally it serves metrics on `8080`. It mounts host system directories to inspect Docker and system resource usage.

## Run the stack

From the project root, run:

```bash
docker compose up -d
```

## Stop the stack

```bash
docker compose down
```

To also remove volumes:

```bash
docker compose down -v
```

## Access the interfaces

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- cAdvisor: http://localhost:8081

## Grafana login

Default Grafana credentials:

- Username: `admin`
- Password: `admin`

After logging in, add Prometheus as a data source with the URL:

```text
http://prometheus:9090
```

## How the monitoring pipeline works

1. cAdvisor collects container and system metrics.
2. Prometheus scrapes those metrics on a fixed interval.
3. Grafana queries Prometheus to display dashboards.

This creates a simple monitoring flow for Docker container health and resource usage.

## Notes

- This is intended for local monitoring and learning.
- For production, you would typically add authentication, persistent storage for Prometheus, alert rules, and backup/retention policies.
