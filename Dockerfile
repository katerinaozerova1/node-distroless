# Capital One–style containerized Node onboarding (see c1_sealights_implementation.txt):
# - slnodejs in package.json / npm ci
# - NODE_OPTIONS=-r ./node_modules/slnodejs/lib/preload.js
# - SL_labId, HTTP_PROXY (Bogiefile container_env in real deployments)
# - Do NOT bake tokens into the image. Pass SL_TOKEN and SL_BUILD_SESSION_ID at runtime.
#   In a full pipeline, SL_BUILD_SESSION_ID is produced by `npx slnodejs config` (writes buildSessionId); the same id is used for scan, tests, and runtime per SeaLights Node agent docs.
#
# slnodejs preload reads SL_TOKEN / SL_BUILD_SESSION_ID from the environment (see node_modules/slnodejs/lib/preload.js).
#
# Repository layout: app.js and package.json sit at the repo root. WORKDIR /app copies them to /app/app.js (not repo/app/app.js).
#
# Build node_modules on Chainguard (Wolfi), not Debian — slnodejs may ship native bits; mixing Debian-built
# modules with a Wolfi runtime often crashes Node before listen(), which shows up as curl connection refused.

FROM cgr.dev/chainguard/node:latest-dev AS deps
WORKDIR /app
USER root
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

# Use absolute paths: with CMD ["node","app.js"], slnodejs can mis-resolve argv and invoke `-- /app/node app.js`
# (treating `/app/node` as the script). Wolfi/Chainguard ships Node at /usr/bin/node.
CMD ["/usr/bin/node", "/app/app.js"]
