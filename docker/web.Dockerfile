# ================================================================
# # Web (Next.js) — Dockerfile
# # - Next 16 / Node 22
# # - 本番ビルドして next start で起動
# # ================================================================

# -------------------------
# deps: 開発依存も含めたパッケージインストール
# -------------------------
FROM node:22-bookworm-slim AS deps

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate

COPY apps/frontend/package.json apps/frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# -------------------------
# builder: Next.js をビルドし、本番依存に絞る
# -------------------------
FROM node:22-bookworm-slim AS builder

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate

COPY --from=deps /app/node_modules ./node_modules
COPY apps/frontend ./

RUN pnpm build
RUN CI=true pnpm prune --prod

# -------------------------
# runtime: 実行環境
# -------------------------
FROM node:22-bookworm-slim AS runtime

ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0

WORKDIR /app

COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["sh", "-c", "node_modules/.bin/next start -H ${HOSTNAME} -p ${PORT}"]
