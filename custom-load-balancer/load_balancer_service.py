# Import required libraries for threading and HTTP requests
import threading
import requests
import time
from config import settings

class LoadBalancerService:
    def __init__(self):
        # Get the list of server URLs for both clusters from configuration
        self.cluster1_urls = settings.get_cluster1_urls()
        self.cluster2_urls = settings.get_cluster2_urls()
        # Dictionary to store response times for each server in cluster 1
        self.cluster1_times = {}
        # Dictionary to store response times for each server in cluster 2  
        self.cluster2_times = {}
        self.running = False
    
    def _check_server(self, url):
        # Try to ping the server's health endpoint
        try:
            # Send GET request to /health endpoint with 5 second timeout
            response = requests.get(f"{url}/health", timeout=5)
            # Calculate response time in milliseconds
            response_time = response.elapsed.total_seconds() * 1000
            # Return response time if server is healthy (200 status), otherwise return None
            return response_time if response.status_code == 200 else None
        except:
            # If any error occurs returns None (unreachable server)
            return None
    
    def _health_check(self):
        # Main loop that runs infinitly to check for response timn
        while self.running:
            # Check health and response time for each server in cluster 1
            for url in self.cluster1_urls:
                self.cluster1_times[url] = self._check_server(url)
            
            # Check health and response time for each server in cluster 2
            for url in self.cluster2_urls:
                self.cluster2_times[url] = self._check_server(url)
            
            # Wait 1 second each time
            time.sleep(1)
    
    def get_fastest(self, cluster):
        # Select the appropriate response times dictionary based on cluster name
        times = self.cluster1_times if cluster == 'cluster1' else self.cluster2_times
        # Return None if no servers have been checked yet
        if not times:
            return None
        # Find and return the URL of the server with the lowest response time
        # Initialize variables to track the fastest server
        fastest_url = None
        fastest_time = float('inf')  # Start with infinity so any real time will be smaller
        
        # Loop through each server and its response time
        for url, response_time in times.items():
            # Skip servers that are unreachable (None response time)
            if response_time is None:
                continue
            # If this server's response time is faster than our current best we take it
            if response_time < fastest_time:
                fastest_time = response_time
                fastest_url = url
        
        # Return the URL of the server with the fastest response time
        return fastest_url
    
    def forward_request_to_cluster(self, cluster_name: str):
        # Find the fastest server in the specified cluster
        fastest_url = self.get_fastest(cluster_name)
        
        # If no server is available, return error
        if not fastest_url:
            return {"error": f"No servers available in {cluster_name}"}
        
        # Forward the request to the fastest server and return its response
        try:
            response = requests.get(fastest_url, timeout=5)
            return response.text
            
        except Exception as e:
            return {"error": f"Failed to reach server {fastest_url}: {str(e)}"}
    def start(self):
        # Set the running flag to True to start the health checking loop
        self.running = True
        # Create a new thread to run the health checking in the background
        thread = threading.Thread(target=self._health_check)
        # Start the background thread
        thread.start()
        return thread


load_balancer = LoadBalancerService()