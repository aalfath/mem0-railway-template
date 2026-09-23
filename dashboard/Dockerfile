# Mem0 v2.2.0 dashboard (server/dashboard from the tagged release). Build with the repo root as context.
FROM alpine:3.24.2 AS source
ARG MEM0_VERSION=2.2.0
ARG MEM0_SHA256=30d1d5545422c10f3d6e1f9bffe7147ac8e4f9655b1aad5a8248ca372a078315
ADD https://github.com/mem0ai/mem0/archive/refs/tags/v${MEM0_VERSION}.tar.gz /tmp/mem0.tar.gz
RUN set -eux; \
    echo "${MEM0_SHA256}  /tmp/mem0.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/mem0.tar.gz -C /tmp; \
    mv /tmp/mem0-${MEM0_VERSION}/server/dashboard /dashboard

FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

FROM base AS builder
COPY --from=source /dashboard/ ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile
ENV NEXT_TELEMETRY_DISABLED=1
# Placeholders replaced at runtime by the upstream entrypoint.sh
ENV NEXT_PUBLIC_API_URL=NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_INSTANCE_NAME=NEXT_PUBLIC_INSTANCE_NAME
RUN pnpm run build

FROM base AS runner
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=3000 HOSTNAME=0.0.0.0
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=source --chown=nextjs:nodejs /dashboard/entrypoint.sh /home/nextjs/entrypoint.sh
RUN chmod +x /home/nextjs/entrypoint.sh
USER nextjs
EXPOSE 3000
ENTRYPOINT ["/home/nextjs/entrypoint.sh"]
CMD ["node", "server.js"]
