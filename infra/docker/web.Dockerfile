# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS deps

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app/apps/frontend

RUN corepack enable && corepack prepare pnpm@10 --activate

COPY apps/frontend/package.json apps/frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM node:22-bookworm-slim AS builder

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app/apps/frontend

RUN corepack enable && corepack prepare pnpm@10 --activate

COPY --from=deps /app/apps/frontend/node_modules ./node_modules
COPY apps/frontend ./

RUN pnpm build

FROM node:22-bookworm-slim AS runtime

ENV NODE_ENV=production \
    PNPM_HOME=/pnpm \
    PATH=/pnpm:$PATH \
    PORT=3000

WORKDIR /app/apps/frontend

RUN corepack enable && corepack prepare pnpm@10 --activate

COPY --from=builder /app/apps/frontend .

EXPOSE 3000

CMD ["sh", "-c", "pnpm start -p ${PORT}"]
