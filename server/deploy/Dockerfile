# syntax=docker/dockerfile:1
# EasyCraft's Nakama for the internet: the official image with the game's server logic built in.
# docker-compose.yml builds it from the server/ folder (context ..), so both modules/ (the
# TypeScript source) and deploy/ (this kit) are in reach. Dockerfile.dockerignore keeps
# node_modules/, build/, .env and backups out of the build.
ARG NAKAMA_VERSION=3.41.0
ARG NODE_VERSION=24

# Stage 1: build the TypeScript module into plain ES5 JavaScript (server/README.md).
FROM node:${NODE_VERSION}-alpine AS module
WORKDIR /modules
COPY modules/package.json modules/package-lock.json ./
COPY modules/vendor ./vendor
RUN npm ci --no-audit --no-fund
COPY modules/ ./
RUN npm run build && test -s build/index.js

# Stage 2: Nakama with the built module, the production settings and the start check. No Node,
# no TypeScript source and no secrets end up in this image.
FROM heroiclabs/nakama:${NAKAMA_VERSION}
COPY --from=module /modules/build/ /nakama/data/modules/build/
COPY deploy/nakama/production.yml /nakama/data/production.yml
COPY --chmod=755 deploy/nakama/start.sh /nakama/start.sh
ENTRYPOINT ["/nakama/start.sh"]
