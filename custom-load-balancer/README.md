# Custom Load Balancer

FastAPI-based load balancer that automatically discovers and routes requests to the fastest available servers in two clusters.

## Setup

This project uses `uv` for dependency management.

### Install uv

First install uv: https://docs.astral.sh/uv/#highlights

### Environment Variables

Create a `.env` file in the project root with:

```
CLUSTER1_URLS= your_cluster1_server_url_1,your_cluster1_server_url_2,...
CLUSTER2_URLS= your_cluster2_server_url_1,your_cluster2_server_url_2,...
```

Alternatively, set these as system environment variables.

## Running

```bash
uv run fastapi dev --port <port>
```

## Endpoints

- `/` - Returns the status and response times of all servers in both clusters
- `/cluster1` - Routes request to the fastest available server in cluster 1
- `/cluster2` - Routes request to the fastest available server in cluster 2
