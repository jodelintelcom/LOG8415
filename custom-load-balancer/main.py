from typing import Union
import requests
from fastapi import FastAPI
from load_balancer_service import load_balancer

app = FastAPI()

# Start loadbalancer service (will ping the servers from each cluster to see what is the best fit)
load_balancer.start()


@app.get("/")
def read_root():
    # Return the status of both clusters with their response times
    return {
        "cluster1_status": load_balancer.cluster1_times,
        "cluster2_status": load_balancer.cluster2_times
    }

@app.get("/cluster1")
def cluster1_request():
    # Use helper function to forward request to cluster1
    return load_balancer.forward_request_to_cluster('cluster1')

@app.get("/cluster2")
def cluster2_request():
    # Use helper function to forward request to cluster2
    return load_balancer.forward_request_to_cluster('cluster2')
