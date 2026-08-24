# hello-fastify

Minimal Node.js/Fastify service, containerized and deployed to EKS behind Traefik.

## Design

- The app itself is **HTTP-only** — no TLS logic, no certs, in the Fastify
  process or the container. It just listens on `PORT` (default `3000`).
- **Traefik owns HTTPS.** It's the ingress layer on the cluster; if/when TLS
  is turned on, that's entirely a Traefik entrypoint/cert-resolver concern.
  The Kubernetes Service and the Deployment never change for that.
- Routes:
  - `GET /` — sample JSON response
  - `GET /healthz` — liveness
  - `GET /readyz` — readiness

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
        ├── ingress.yaml        # style: ingress   (vanilla Ingress, ingressClassName: traefik)
        ├── ingressroute.yaml   # style: ingressRoute (Traefik CRD)
        └── NOTES.txt
```

## Build & push the image

```bash
pnpm install --frozen-lockfile   # generates/refreshes pnpm-lock.yaml if missing

docker build -t <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify:1.0.0 .
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify:1.0.0
```

## Deploy to EKS

Pick the ingress style that matches how Traefik is installed in the cluster
(set in `values.yaml` under `ingress.style`, default is `ingress`):

- `ingress` — a plain `networking.k8s.io/v1` Ingress with
  `ingressClassName: traefik`. Works with any Traefik install that watches
  standard Ingress objects — no CRDs required.
- `ingressRoute` — Traefik's own `IngressRoute` CRD, if Traefik's CRDs are
  installed and that's the house style.

```bash
helm upgrade --install hello-fastify ./helm/hello-fastify \
  --namespace hello-fastify --create-namespace \
  --set image.repository=<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/hello-fastify \
  --set image.tag=1.0.0 \
  --set ingress.host=hello-fastify.example.com \
  --set ingress.style=ingress
```

To switch to the IngressRoute CRD instead:

```bash
--set ingress.style=ingressRoute
```

## Turning HTTPS on later

Nothing in this chart needs to change on the app/Service side. On the
Traefik side, typically:

1. Add a cert-resolver (e.g. ACME/Let's Encrypt, or an AWS ACM cert on the
   NLB fronting Traefik) on the `websecure` entrypoint.
2. Add `websecure` to `ingress.entryPoints` (IngressRoute style) or the
   equivalent TLS annotations/route (Ingress style).
3. Optionally redirect `web` → `websecure` at the Traefik entrypoint level.

The Fastify process itself never terminates TLS — it stays HTTP-only behind
Traefik either way.
