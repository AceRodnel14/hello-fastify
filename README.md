# hello-fastify

Minimal Node.js/Fastify service, containerized and deployed to EKS behind an
existing Traefik ingress.

## Design

- The app itself is **HTTP-only** — no TLS logic, no certs, in the Fastify
  process or the container. It just listens on `PORT` (default `8000`).
- Routed through Traefik's `web` entrypoint only, plain HTTP. No HTTPS
  conversion for this service.
- Routes:
  - `GET /` — `Hello <VAR>` (VAR is optional, defaults to `world`)
  - `GET /healthz` — liveness

## Layout

```
hello-fastify/
├── server.ts                  # Fastify app
├── package.json
├── tsconfig.json
├── Dockerfile                 # multi-stage: deps → build → prod-deps → distroless runtime
├── .dockerignore
└── helm/hello-fastify/        # Helm chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── serviceaccount.yaml
        ├── ingress.yaml        # plain Ingress, ingressClassName: traefik, web entrypoint only
        ├── scaledobject.yaml   # KEDA CPU/memory autoscaling (off by default)
        └── NOTES.txt
```

## Build & push the image

```bash
pnpm install --frozen-lockfile   # generates/refreshes pnpm-lock.yaml if missing

docker build -t <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify:1.0.0 .
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify:1.0.0
```

## Deploy to EKS

Assumes Traefik is already running in the cluster and watching Ingress
objects.

```bash
helm upgrade --install hello-fastify ./helm/hello-fastify \
  --namespace hello-fastify --create-namespace \
  --set image.repository=<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify \
  --set image.tag=1.0.0 \
  --set ingress.host=hello-fastify.example.com
```

