# -------- Builder --------
FROM node:20-bullseye AS builder
WORKDIR /app

# Enable Corepack for Yarn 4
RUN corepack enable

# Add workspace files from backstage subdirectory
COPY backstage/package.json backstage/yarn.lock backstage/tsconfig.json ./
COPY backstage/packages ./packages
COPY app-config*.yaml ./

# Install deps & build
RUN yarn install --frozen-lockfile
RUN yarn tsc -b
RUN yarn workspace backend build

# -------- Runner --------
FROM node:20-bullseye AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy built workspace
COPY --from=builder /app ./

# Backstage will read config files listed in APP_CONFIG
ENV APP_CONFIG=app-config.local.yaml
EXPOSE 7007
CMD ["node", "packages/backend", "--config", "app-config.local.yaml"]
