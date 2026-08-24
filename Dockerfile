# syntax=docker/dockerfile:1.7

##
## 1. deps — install full deps (incl. dev) for the build stage
##
FROM node:24-slim AS deps
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY package.json ./
RUN pnpm install

##
## 2. build — compile TypeScript
##
FROM node:24-slim AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY --from=deps /app/node_modules ./node_modules
COPY package.json tsconfig.json ./
COPY server.ts ./
RUN pnpm run build

##
## 3. prod-deps — install prod-only deps, no dev dependencies in the final image
##
FROM node:24-slim AS prod-deps
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY package.json ./
COPY --from=deps /app/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

##
## 4. runtime — distroless, non-root, HTTP only (Traefik terminates TLS upstream)
##
FROM gcr.io/distroless/nodejs24-debian12:nonroot AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    PORT=8000 \
    HOST=0.0.0.0

COPY --from=prod-deps --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=build --chown=nonroot:nonroot /app/dist ./dist
COPY --chown=nonroot:nonroot package.json ./

USER nonroot
EXPOSE 8000

# distroless has no shell, so no HEALTHCHECK CMD here — readiness/liveness
# is handled by Kubernetes probes hitting /healthz and /readyz instead.

CMD ["dist/server.js"]
