# Capital One–style containerized Node onboarding (see c1_sealights_implementation.txt):
# - slnodejs in package.json / npm ci
# - NODE_OPTIONS=-r …/node_modules/slnodejs/lib/preload.js
# - SL_labId, HTTP_PROXY (Bogiefile container_env in real deployments)
# - Pass SL_TOKEN and SL_BUILD_SESSION_ID at runtime (see GITHUB-ACTIONS.txt).
#
# IMPORTANT: Do not use WORKDIR /app with CMD ["node", "/app/app.js"]. Node/slnodejs can treat the
# token `node` as a path under cwd and produce argv ['/usr/bin/node', '/app/node', '/app/app.js'],
# so SeaLights runs `-- /app/node /app/app.js` and fails with MODULE_NOT_FOUND. Use WORKDIR /srv and
# /srv/app.js so nothing resolves to `/app/node`.

# Build node_modules on Chainguard (Wolfi), not Debian — native bits must match the runtime OS.

FROM cgr.dev/chainguard/node:latest-dev AS deps
WORKDIR /srv
USER root
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM cgr.dev/chainguard/node:latest
WORKDIR /srv
COPY --chown=65532:65532 --from=deps /srv/node_modules ./node_modules
COPY --chown=65532:65532 package.json app.js ./

ENV NODE_OPTIONS="-r /srv/node_modules/slnodejs/lib/preload.js"
ENV SL_labId="cs5227-repro-dev"
ENV HTTP_PROXY="http://aws-proxy-dev.cloud.capitalone.com:8099"
ENV PORT=3000
EXPOSE 3000

USER 65532:65532

CMD ["node", "/srv/app.js"]
