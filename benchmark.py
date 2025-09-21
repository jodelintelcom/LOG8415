# Import libraries for async HTTP requests and timing
import asyncio
import aiohttp
import time
import os
import json

# Function to make HTTP request to cluster and return response
async def call_endpoint_http(session, request_num, cluster):
    # Get load balancer IP from environment or use default
    base_url = os.getenv("LB_IP", "http://3.84.142.9:8080")
    url = f"{base_url}/{cluster}"

    # Set HTTP headers
    headers = {'content-type': 'application/json'}

    try:
        # Make async HTTP GET request to cluster endpoint
        async with session.get(url, headers=headers) as response :
            status_code = response.status
            response_json = await response.json()

        # Parse JSON response 
        
        cluster_id = response_json.get("instance_id", "unknown")

        # Print request results with instance ID
        print(f"Request {request_num}  | Status Code : {status_code}| cluster : {cluster}: | Instance ID : {cluster_id}")
        return status_code , response_json

    except Exception as e :
        # Handle and log any request failures
        print(f"Request {request_num} (cluster={cluster}): Failed - {str(e)}")
        return None, str(e)

# Main function to benchmark both clusters
async def main():

    # Number of concurrent requests to send to each cluster
    num_requests = 1000

    # Test cluster2 (large EC2 instances)
    print(f"Starting {num_requests} requests to cluster2...")
    start_time2 = time.time()
    async with aiohttp.ClientSession() as session:
        # Create list of async tasks for all requests
        tasks = [call_endpoint_http(session, i,"cluster2") for i in range (num_requests)]
        # Execute all requests concurrently
        await asyncio.gather(*tasks)
    end_time2 = time.time()

    # Test cluster1 (micro EC2 instances)
    print(f"\nStarting {num_requests} requests to cluster1...")
    start_time1 = time.time()
    async with aiohttp.ClientSession() as session:
        # Create list of async tasks for all requests
        tasks = [call_endpoint_http(session, i,"cluster1") for i in range (num_requests)]
        # Execute all requests concurrently
        await asyncio.gather(*tasks)
    end_time1 = time.time()

    # Calculate and display performance results
    total_time1 = end_time1 - start_time1
    total_time2 = end_time2 - start_time2
    average_time1 = total_time1 / num_requests
    average_time2 = total_time2 / num_requests

    print ("\n=== BENCHMARK RESULTS ===")
    print (f"Total time taken cluster1: {total_time1 :.6f} seconds")
    print (f"Total time taken cluster2: {total_time2 :.6f} seconds")
    print (f"Average time per request cluster1: {average_time1 :.6f} seconds")
    print (f"Average time per request cluster2: {average_time2 :.6f} seconds")

if __name__ == "__main__":
    asyncio.run(main())