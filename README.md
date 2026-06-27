# learnhub-core
comprehensive learning management

## Prerequisites (local)

- Container engine: **Colima** (Mac)
- Local development uses **Docker Compose**

```bash
# If Colima is not running
colima start

# Verify Docker is pointing at Colima
docker context ls
```

## Tech stack

| Layer | Choice |
|---|---|
| Backend | FastAPI (Python **3.14**) |
| Frontend | React + TypeScript (Vite, Node **22**) |
| Local dev | Docker Compose (hot reload) |
| Production | Cloud Run (single container) |

## Directory layout

```
learnhub-core/
├── backend/
│   ├── app/
│   │   └── main.py
│   ├── Dockerfile.dev      # local development
│   └── requirements.txt
├── frontend/
│   ├── src/
│   ├── Dockerfile.dev      # local development
│   └── package.json
├── Dockerfile              # Cloud Run (multi-stage, single container)
├── docker-compose.yml      # local dev (hot reload)
├── docker-compose.prod.yml # prod-like single-container check
└── docs/
```

- API routes live under `/api/*`; in development the frontend is at http://localhost:5173 (Vite proxies `/api` to the backend)
- In production, FastAPI serves the React build output at `/`
- Health check: `GET /api/health`

## Local development (default)

```bash
docker compose up --build
```

| URL | Description |
|---|---|
| http://localhost:5173 | Frontend (hot reload) |
| http://localhost:8000/api/health | API direct |

Edits under `backend/app` and `frontend/src` are picked up automatically inside the containers.

Frontend `node_modules` live in a Docker named volume (not on the host).

## Prod-like check (single container)

To run with the same Dockerfile used on Cloud Run:

```bash
docker compose -f docker-compose.prod.yml up --build
```

http://localhost:8080

## Deploy to Cloud Run (example)

```bash
gcloud run deploy learnhub-core \
  --source . \
  --region=asia-northeast1 \
  --port=8080 \
  --allow-unauthenticated
```

To enable IAP, configure IAP in the console first, then use `--no-allow-unauthenticated --iap`.
