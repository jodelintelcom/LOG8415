from fastapi import FastAPI, HTTPException, Header
import requests
import os
app = FastAPI()

API_KEY = "log8415e"

PROXY_ENDPOINT = "http://3.237.62.64:8001/query"


BLOCKED_SQL_PATTERNS = ["drop table", "truncate", "shutdown", "alter table"]

def check_query(sql: str):
    s = sql.lower()
    if "delete from" in s and "cluster_benchmark" not in s:
        return False
    return not any(cmd in s for cmd in BLOCKED_SQL_PATTERNS)


@app.post("/query")
def secure_query(payload: dict, x_api_key: str = Header(None)):

    if x_api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Forbidden")

    sql = payload.get("sql")
    strategy = payload.get("strategy", "direct")

    if not sql:
        raise HTTPException(status_code=400, detail="You should provide a SQL query...")

    if not check_query(sql):
        raise HTTPException(status_code=400, detail="Your query has been blocked by the gatekeeper...")

    try:
        response = requests.post(PROXY_ENDPOINT, json={
            "sql": sql,
            "strategy": strategy
        })
        return response.json()

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
