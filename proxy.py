from fastapi import FastAPI, HTTPException
import mysql.connector
import random
import subprocess
import json
import time

app = FastAPI()


MANAGER = "10.0.0.11"
WORKERS = [
    "10.0.0.12",
    "10.0.0.13"
]

DB_USER = "root"
DB_PASS = ""
DB_NAME = "sakila"

def check_action(query: str):
    writes = [
    "insert", "update", "delete", "alter",
    "drop", "create", "truncate", "replace"
    ]
    return any(w in query.lower() for w in writes)

def choose_best_worker():
    latencies = []
    for worker in WORKERS:
        try:
            result = subprocess.run(
                ["ping", "-c", "1", worker],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            out = result.stdout
            latency = float(out.split("time=")[1].split(" ms")[0])
            latencies.append((latency, worker))
        except:
            continue

    if not latencies:
        return random.choice(WORKERS)

    latencies.sort()
    return latencies[0][1]

def run_sql_query(host: str, query: str):

    conn = mysql.connector.connect(
        host=host,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME
    )

    cursor = conn.cursor()

    try:
        cursor.execute(query)

        if cursor.with_rows:
            result = cursor.fetchall()
        else:
            conn.commit()
            result = {"rows_affected": cursor.rowcount}

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        conn.close()

@app.post("/query")
def route_query(payload: dict):

    strategy = payload.get("strategy", "direct")
    sql = payload.get("sql")

    if not sql:
        raise HTTPException(status_code=400, detail="No SQL query provided.")

    if strategy == "direct":
        host = MANAGER

    elif strategy == "random":
        if check_action(sql):
            host = MANAGER
        else:
            host = random.choice(WORKERS)

    elif strategy == "custom":
        if check_action(sql):
            host = MANAGER
        else:
            host = choose_best_worker()

    else:
        raise HTTPException(status_code=400, detail="Unknown strategy")

    result = run_sql_query(host, sql)

    return {
        "strategy": strategy,
        "target": host,
        "query": sql,
        "result": result
    }