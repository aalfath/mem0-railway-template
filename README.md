# Deploy and Host Mem0 on Railway

Mem0 is an open-source memory layer for AI agents and assistants. It extracts facts from conversations with an LLM, stores them as vector embeddings, and returns the relevant memories for each user, agent or session when you search. Apps use it through its REST API or the official Python and TypeScript SDKs.

## About Hosting Mem0

This template deploys the Mem0 v2.2.0 self-hosted server, its web dashboard and a Railway Postgres database. Memories are stored with pgvector, which Railway's Postgres already includes. Users and API keys live in a second database created on first start. You must provide an OpenAI API key when deploying; LLM and embedding calls are billed by OpenAI. The first account registered in the dashboard becomes admin, and registration then closes, so register right after deploying. The API also accepts a generated admin API key. Telemetry is off. The memory history database is kept on a small volume.

## Common Use Cases

- Giving chatbots and AI agents long-term, per-user memory across sessions
- Personalizing assistants with user preferences and facts learned from conversations
- A self-hosted alternative to the Mem0 cloud platform that keeps memories in your own database

## Dependencies for Mem0 Hosting

- Mem0 v2.2.0 server and dashboard built from [aalfath/mem0-railway-template](https://github.com/aalfath/mem0-railway-template) (upstream release tarball, checksum-pinned; `mem0ai==2.2.0`)
- Railway Postgres (`ghcr.io/railwayapp-templates/postgres-ssl:18`) with pgvector
- An OpenAI API key (default models `gpt-5-mini` and `text-embedding-3-small`)

### Deployment Dependencies

- [Mem0 open-source documentation](https://docs.mem0.ai/open-source/overview)
- [Mem0 v2.2.0 release](https://github.com/mem0ai/mem0/releases/tag/v2.2.0)
- [Mem0 REST API server](https://docs.mem0.ai/open-source/features/rest-api)
- [Railway volumes](https://docs.railway.com/reference/volumes)

### Implementation Details

| Service | Source | Networking | Storage |
| --- | --- | --- | --- |
| mem0 | repo, `Dockerfile` | public API on 8000; private IPv4/IPv6 | volume at `/app/history` |
| dashboard | repo, `dashboard/Dockerfile` | public domain on 3000 | none |
| Postgres | Railway Postgres 18 (pgvector) | private only | volume |

Add and search memories:

```bash
curl -X POST "$MEM0_API_URL/memories" -H "X-API-Key: $ADMIN_API_KEY" -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "I prefer dark roast coffee"}], "user_id": "alice"}'
curl -X POST "$MEM0_API_URL/search" -H "X-API-Key: $ADMIN_API_KEY" -H "Content-Type: application/json" \
  -d '{"query": "What coffee does Alice like?", "user_id": "alice"}'
```

From another Railway service, use `${{mem0.MEM0_PRIVATE_URL}}`. Create per-user API keys in the dashboard instead of sharing the admin key. Interactive API docs are at `/docs` on the API domain.

| Variable | Service | Default | Purpose |
| --- | --- | --- | --- |
| `OPENAI_API_KEY` | mem0 | none (required) | LLM and embeddings |
| `ADMIN_API_KEY` | mem0 | generated secret | Admin access via `X-API-Key` |
| `JWT_SECRET` | mem0 | generated secret | Signs dashboard login tokens |
| `MEM0_TELEMETRY` | mem0 | `false` | Upstream anonymous telemetry |
| `RAILWAY_DOCKERFILE_PATH` | dashboard | `dashboard/Dockerfile` | Builds the dashboard image |

Notes:

- To use Anthropic or Gemini instead, add `ANTHROPIC_API_KEY` or `GOOGLE_API_KEY` and change the provider from the dashboard or `POST /configure`. OpenAI-compatible endpoints work through `OPENAI_BASE_URL`.
- The API only accepts browser requests from the dashboard origin set in `DASHBOARD_URL` (CORS); keep the service names `mem0` and `dashboard`.
- Upstream fixes applied in the image: `libpq5` installed (needed by `psycopg`), `mem0ai` pinned, and `uvicorn --reload` removed.
- Back up Postgres; it holds all memories, users and API keys.

This is a community-maintained deployment package and does not imply affiliation with or endorsement by Mem0.

## Why Deploy Mem0 on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Mem0 on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
