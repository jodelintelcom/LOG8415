# Web Server

Simple FastAPI web server that provides instance information and health checks.

## Setup

This project uses `uv` for dependency management.

### Install uv

First install uv: https://docs.astral.sh/uv/#highlights

### Environment Variables

Create a `.env` file in the project root with:

```
cluster_name = your_cluster_name
instance_id = your_instance_id
```

Alternatively, set these as system environment variables.

## Running

```bash
uv run fastapi dev --port <port>
```

## Endpoints

- `/` - Returns instance ID and cluster name
- `/health` - Health check endpoint