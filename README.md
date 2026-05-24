# urlshortener-frontend

Static frontend for [urlshortener-backend](https://github.com/AaronShemtov/urlshortener-backend),
served by nginx in a Kubernetes pod. Deployed via Flux from
[personal-k8s](https://github.com/AaronShemtov/personal-k8s).

## Current stack

- Plain HTML + CSS + vanilla JavaScript (no build step)
- `nginxinc/nginx-unprivileged:1.27-alpine` runtime — runs as UID 101 (non-root)
- Listens on port 8080 to satisfy restricted PodSecurityStandard
- Same-origin API calls via `/shorten` and `/createcustom` — Envoy Gateway path-routes
  these to the backend Service. No CORS, no separate API host.

## Future stack (roadmap)

The separate repository exists so a planned migration to a modern SPA framework
doesn't churn the backend git history:

- React + Vite, or Svelte + SvelteKit (TBD)
- TypeScript, component-level caching, optimistic UI for `POST /shorten`
- Multi-stage Dockerfile: Node build stage → nginx runtime stage

## Build & push

```bash
docker buildx build \
  --platform linux/arm64 \
  --tag il-jerusalem-1.ocir.io/<tenancy-namespace>/urlshortener-frontend:<tag> \
  --push .
```

Target `linux/arm64` because OKE nodes are Ampere A1. Push requires OCIR login.

## Local preview

```bash
docker build -t urlshortener-frontend:dev .
docker run --rm -p 8080:8080 urlshortener-frontend:dev
# open http://localhost:8080
```

POST endpoints fail (no backend in this image), but the page renders.

## What's exposed in the image

| Path | Status |
|------|--------|
| `/` | Returns `index.html` |
| `/favicon_round.ico`, `/*.webp` | Static assets, 30-day cache headers |
| `/healthz` | Returns `200 ok` for Kubernetes probes |
| Anything else | Falls through to `index.html` (SPA-friendly) |
