# Mem0 on Railway

Mem0 v2.2.0 self-hosted server packaged for Railway:

- `Dockerfile`: the REST API from `server/` in the tagged release (tarball checksum pinned, `mem0ai==2.2.0`), run without `--reload`, as a non-root user, with Alembic migrations and app-database creation on start.
- `dashboard/Dockerfile`: the Mem0 dashboard from the same release.

The full template overview is published on the Railway marketplace.
