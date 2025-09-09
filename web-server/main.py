from instance_utils import get_cluster_name, get_instance_id
from fastapi import FastAPI

app = FastAPI()


# Root endpoint that returns instance information
@app.get("/")
def read_root():
    return {"instance_id": get_instance_id(), "cluster": get_cluster_name()}

# Endpoint to check if the server is healthy (LB will call it to check if we can redirect to this instance)
@app.get("/health")
def pong():
    return "healthy"