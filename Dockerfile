# Capital One–style containerized Node onboarding (see c1_sealights_implementation.txt):
# - slnodejs in package.json / npm ci
# - NODE_OPTIONS=-r ./node_modules/slnodejs/lib/preload.js
# - SL_labId, HTTP_PROXY (Bogiefile container_env in real deployments)
# - Do NOT bake tokens into the image. Pass SL_TOKEN and SL_BUILD_SESSION_ID at runtime.
#   In a full pipeline, SL_BUILD_SESSION_ID is produced by `npx slnodejs config` (writes buildSessionId); the same id is used for scan, tests, and runtime per SeaLights Node agent docs.
#
# slnodejs preload reads SL_TOKEN / SL_BUILD_SESSION_ID from the environment (see node_modules/slnodejs/lib/preload.js).

FROM node:20-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Chainguard runtime user is UID/GID 65532; some tags omit the name "nonroot" in passwd, which breaks
# `USER nonroot`. Use numeric ids (same as typical distroless non-root).
FROM cgr.dev/chainguard/node:latest
WORKDIR /app
COPY --chown=65532:65532 --from=deps /app/node_modules ./node_modules
COPY --chown=65532:65532 package.json app.js ./

ENV NODE_OPTIONS="-r /app/node_modules/slnodejs/lib/preload.js"
ENV SL_labId="cs5227-repro-dev"
ENV HTTP_PROXY="http://aws-proxy-dev.cloud.capitalone.com:8099"
ENV PORT=3000
EXPOSE 3000

USER 65532:65532

CMD ["node", "/app/app.js"]
