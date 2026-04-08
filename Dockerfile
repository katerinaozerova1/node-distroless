# Chainguard Node image: minimal, no /bin/sh (CS-5227 repro)
FROM cgr.dev/chainguard/node:latest

WORKDIR /app

ARG PRELOAD_FILE=preload-sealights-execsync.js

COPY --chown=nonroot:nonroot package.json app.js fake-sl-cli.js sltoken.txt buildSessionId ./
COPY --chown=nonroot:nonroot ${PRELOAD_FILE} preload-active.js

ENV NODE_OPTIONS="-r /app/preload-active.js"
ENV PORT=3000
EXPOSE 3000

USER nonroot:nonroot

CMD ["node", "/app/app.js"]
