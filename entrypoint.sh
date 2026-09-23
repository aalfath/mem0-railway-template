#!/bin/sh
set -eu

# The Railway volume mounts root-owned; hand it to the app user once.
mkdir -p /app/history
[ "$(stat -c %u /app/history)" = "1000" ] || chown -R mem0:mem0 /app/history

# Wait for Postgres, then create the app database (users, API keys) if missing.
# Memories live in POSTGRES_DB via pgvector; mem0 creates the extension itself.
python - <<'PY'
import os, sys, time
import psycopg
from psycopg import sql

params = dict(
    host=os.environ.get("POSTGRES_HOST", "postgres"),
    port=os.environ.get("POSTGRES_PORT", "5432"),
    user=os.environ.get("POSTGRES_USER", "postgres"),
    password=os.environ.get("POSTGRES_PASSWORD", ""),
    dbname=os.environ.get("POSTGRES_DB", "postgres"),
    autocommit=True,
    connect_timeout=5,
)
app_db = os.environ.get("APP_DB_NAME", "mem0_app")
for attempt in range(60):
    try:
        conn = psycopg.connect(**params)
        break
    except psycopg.OperationalError as exc:
        print(f"waiting for postgres: {exc}".strip(), flush=True)
        time.sleep(2)
else:
    sys.exit("postgres not reachable")
with conn:
    if not conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (app_db,)).fetchone():
        conn.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(app_db)))
        print(f"created database {app_db}", flush=True)
PY

# Migrate and serve as the unprivileged user. An empty host listens on IPv4 and IPv6 (Railway private network).
export HOME=/home/mem0
exec setpriv --reuid=mem0 --regid=mem0 --init-groups sh -c '
  alembic upgrade head
  exec uvicorn main:app --host "" --port "${PORT:-8000}" --proxy-headers --forwarded-allow-ips "*"
'
