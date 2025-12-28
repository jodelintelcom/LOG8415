from fastapi import FastAPI, HTTPException
import random
import subprocess
import pymysql

app = FastAPI()


MANAGER = "10.0.0.196"
WORKERS = [
    "10.0.0.204",
    "10.0.0.98"
]


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
    try:
        conn = pymysql.connect(
            host=host,
            user="labuser",
            password="labpass",
            database="sakila",
            autocommit=True
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(query)
                if query.lower().startswith("select"):
                    return cursor.fetchall()
                else:
                    return {"rows_affected": cursor.rowcount}
        finally:
            conn.close()

    except Exception as e:
        return {"error": str(e)}



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