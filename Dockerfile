# Mem0 v2.2.0 self-hosted REST API (server/ from the tagged release), production settings.
FROM python:3.12-slim

ARG MEM0_VERSION=2.2.0
ARG MEM0_SHA256=30d1d5545422c10f3d6e1f9bffe7147ac8e4f9655b1aad5a8248ca372a078315

WORKDIR /app
ADD https://github.com/mem0ai/mem0/archive/refs/tags/v${MEM0_VERSION}.tar.gz /tmp/mem0.tar.gz
RUN set -eux; \
    apt-get update; apt-get install -y --no-install-recommends libpq5; rm -rf /var/lib/apt/lists/*; \
    echo "${MEM0_SHA256}  /tmp/mem0.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/mem0.tar.gz -C /tmp; \
    cp -a /tmp/mem0-${MEM0_VERSION}/server/. /app/; \
    rm -rf /tmp/mem0.tar.gz /tmp/mem0-${MEM0_VERSION} /app/dashboard; \
    sed -i "s/^mem0ai>=.*/mem0ai==${MEM0_VERSION}/" requirements.txt; \
    grep -q "^mem0ai==${MEM0_VERSION}$" requirements.txt; \
    pip install --no-cache-dir -r requirements.txt; \
    useradd --system --uid 1000 --create-home mem0; \
    mkdir -p /app/history; chown -R mem0:mem0 /app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENV PYTHONUNBUFFERED=1 PORT=8000 HISTORY_DB_PATH=/app/history/history.db
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
