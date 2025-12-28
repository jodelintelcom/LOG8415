import requests
import time
import os

GATEKEEPER = os.getenv(
    "GATEKEEPER_URL",
    "http://44.201.54.163:8000/query"
)

HEADERS = {"X-API-Key": "log8415e"}

REQUESTS_PER_TEST = 1000
BENCHMARK_TABLE = "cluster_benchmark"

def send_query(sql, strategy="direct"):
    payload = {"sql": sql, "strategy": strategy}
    try:
        r = requests.post(
            GATEKEEPER,
            json=payload,
            headers=HEADERS,
            timeout=5
        )
        return r.json()
    except Exception as e:
        return {"error": str(e)}

def clean_table():
    print("The table is being deleted...")
    send_query(f"DELETE FROM {BENCHMARK_TABLE};", "direct")

def benchmark_strategy(strategy):
    print(f"\n strategy running now is: {strategy.upper()}")

    start = time.time()
    for i in range(REQUESTS_PER_TEST):
        if i % 50 == 0:
            print(f"  READ {i}/{REQUESTS_PER_TEST}...")
        response = send_query(
            "SELECT * FROM actor WHERE actor_id = 1 LIMIT 1;",
            strategy
        )
        if i == 0 :
            print("FULL RESPONSE:", response)

    read_time = time.time() - start
    print(f"Action : READ x{REQUESTS_PER_TEST} → {read_time:.2f}s")

    start = time.time()
    for i in range(REQUESTS_PER_TEST):
        if i % 50 == 0:
            print(f" WRITE {i}/{REQUESTS_PER_TEST}...")
        response = send_query(
            f"INSERT INTO {BENCHMARK_TABLE}(val) VALUES (1);",
            strategy
        )
        if i == 0 :
            print("FULL RESPONSE:", response)

    write_time = time.time() - start
    print(f"Action : WRITE x{REQUESTS_PER_TEST} → {write_time:.2f}s")

    return read_time, write_time

if __name__ == "__main__":
    clean_table()
    results = {}
    for strat in ["direct", "random", "custom"]:
        read_t, write_t = benchmark_strategy(strat)
        results[strat] = (read_t, write_t)

    for strat, (r, w) in results.items():
        print(f"{strat.upper():7} : READ: {r:.2f}s | WRITE: {w:.2f}s")
