# 3pull-app

<p>
  <img src="docs/assets/3pull-logo.png" alt="3pull character icon" />
</p>

モノレポ構成の Web + API + Infra スターターパックです。

## スターター構成

### インフラ

- Infrastructure as Code（Bicep）によるインフラ構築
- PostgreSQL 初期設定スクリプト

### フロントエンド

- 認証: Better Auth
- 国際化対応: i18n（Next.js App Router）
- グローバルステート管理: Zustand
- バリデーション: Zod
- UI フレームワーク: shadcn/ui
- ORM: Drizzle ORM（`auth` スキーマ）

### バックエンド

- 構造化ログ: structlog
- ORM / DB アクセス: SQLAlchemy
- 設定管理 / バリデーション: Pydantic（pydantic-settings）
- マイグレーション: Alembic（`core` スキーマ）
- ASGI プロセスマネージャ: Gunicorn

### 共通

- API 保護: JWT（RS256）

## はじめに（重要）

本プロジェクトのアプリを稼働させるには、次の 2 つが必要です。

- インフラ構築（Azure）
- DB 初期設定（PostgreSQL）

まず次のドキュメントを上から順に実施してください。

1. [`infra/README.md`](infra/README.md)（Bicep による Azure リソース構築）
2. [`db/postgres/init/README.md`](db/postgres/init/README.md)（DB 初期設定スクリプト）

### 基本手順（推奨）

- [`infra/README.md`](infra/README.md) に従って Bicep をすべて構築
- 続けて [`db/postgres/init/README.md`](db/postgres/init/README.md) のスクリプトを実行

### 省略バージョン（ローカル稼働確認向け）

- **Azure Database for PostgreSQL Flexible Server** だけを手動で作成
- 続けて [`db/postgres/init/README.md`](db/postgres/init/README.md) のスクリプトを実行
- `apps/frontend/.env` と `apps/backend/.env` の `DATABASE_URL` を作成したサーバー情報に合わせて設定

DB 初期設定スクリプトでは、主に次を実施します。

- データベース作成
- `auth` / `core` スキーマ作成
- Web/API ロール作成と最小権限付与
- ロールごとの `search_path` 既定値設定

## 前提要件

- Node.js / pnpm
- Python 3.12+ / uv
- PostgreSQL クライアント（`psql`）
- OpenSSL（JWT 鍵生成で使用）

## セットアップ概要

1. フロントエンド環境変数を作成
2. バックエンド環境変数を作成
3. API 保護用 JWT 鍵ペア（公開鍵・秘密鍵）を生成して `.env` へ設定
4. 依存関係をインストール
5. 必要に応じて DB マイグレーション適用
6. Frontend / Backend を起動

## 1) 環境変数ファイルの作成

```bash
cp apps/frontend/.env.example apps/frontend/.env
cp apps/backend/.env.example apps/backend/.env
```

## 2) API 保護用 JWT 鍵の生成と `.env` 反映

このプロジェクトでは次の役割で鍵を使います。

- `JWT_PRIVATE_KEY`（フロントエンド）: API 用 JWT を署名
- `JWT_PUBLIC_KEY`（バックエンド）: 上記 JWT を検証

### 2-1. 鍵ペア生成

```bash
mkdir -p .tmp/jwt
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out .tmp/jwt/jwt_private.pem
openssl rsa -pubout -in .tmp/jwt/jwt_private.pem -out .tmp/jwt/jwt_public.pem
```

### 2-2. `.env` 向け 1 行形式へ変換（`\n` エスケープ）

```bash
JWT_PRIVATE_KEY_ESCAPED="$(awk '{printf "%s\\\\n", $0}' .tmp/jwt/jwt_private.pem)"
JWT_PUBLIC_KEY_ESCAPED="$(awk '{printf "%s\\\\n", $0}' .tmp/jwt/jwt_public.pem)"
```

### 2-3. `apps/frontend/.env` に設定（署名側）

```env
JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
JWT_ISSUER=3pull-web
JWT_AUDIENCE=3pull-api
```

`JWT_PRIVATE_KEY` には `JWT_PRIVATE_KEY_ESCAPED` の値を貼り付けてください。

### 2-4. `apps/backend/.env` に設定（検証側）

```env
JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\n
JWT_ISSUER=3pull-web
JWT_AUDIENCE=3pull-api
```

`JWT_PUBLIC_KEY` には `JWT_PUBLIC_KEY_ESCAPED` の値を貼り付けてください。

注意:

- `JWT_ISSUER` と `JWT_AUDIENCE` はフロントとバックで同じ値に揃えてください。
- PEM を 1 行で持つため `\n` エスケープが必要です。

## 3) 依存関係のインストール

### Frontend

```bash
cd apps/frontend
pnpm install
```

### Backend

```bash
cd apps/backend
uv sync
```

## 4) DB マイグレーション（初回セットアップ時）

### Frontend（auth スキーマ）

Schema source: `apps/frontend/drizzle/schema.ts`  
Migration output: `apps/frontend/drizzle/migrations/`

```bash
npx drizzle-kit generate --name add_auth_models
psql "$DATABASE_URL" -f apps/frontend/drizzle/migrations/0000_add_auth_models.sql
```

## 5) 起動方法

### Frontend 起動前の認証設定

#### Better Auth Secret を設定する

`BETTER_AUTH_SECRET` は Better Auth のセッション保護に使う秘密値です。  
十分に長いランダム文字列を生成して `apps/frontend/.env` に設定してください。

生成例:

```bash
openssl rand -base64 32
```

設定:

```env
BETTER_AUTH_SECRET=<生成したランダム文字列>
```

#### Microsoft Entra ID を利用する場合

以下のドキュメントを参照してアプリ登録を行い、必要値を取得してください。  
https://learn.microsoft.com/ja-jp/entra/identity-platform/v2-protocols-oidc

取得した値を `apps/frontend/.env` に設定します。

```env
MICROSOFT_CLIENT_ID=
MICROSOFT_CLIENT_SECRET=
MICROSOFT_TENANT_ID=
```

#### メール認証（サインアップ）を利用する場合

サインアップ時に確認メール送信が必要なため、Resend の API キーを用意してください。  
次の値を `apps/frontend/.env` に設定します。

```env
RESEND_API_KEY=
EMAIL_SENDER_NAME=
EMAIL_SENDER_ADDRESS=
```

補足:

- ソーシャルログインのみ利用する場合は、メール送信設定がなくても動作します。

### Frontend

```bash
cd apps/frontend
pnpm dev
```

本番相当:

```bash
cd apps/frontend
pnpm build
pnpm start
```

### Backend

```bash
cd apps/backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

本番相当:

```bash
cd apps/backend
uv run gunicorn -k uvicorn.workers.UvicornWorker app.main:app \
  --bind 0.0.0.0:8000 \
  --workers ${GUNICORN_WORKERS:-2} \
  --threads ${GUNICORN_THREADS:-1} \
  --timeout ${GUNICORN_TIMEOUT:-60} \
  --keep-alive ${GUNICORN_KEEPALIVE:-5}
```

## 6) 動作確認（フロントのヘルスチェックページ）

1. フロントエンドを起動し、`http://localhost:3000/ja/health`（または `http://localhost:3000/en/health`）へアクセスします。
2. ログイン済み状態で `ヘルスチェック実行` ボタンを押します。
3. API 保護（JWT）付きで `GET /backend/v1/healthz` が呼ばれ、結果が画面に表示されます。

ヘルスチェックでは Postgres について次の 2 段階を確認します。

- `postgres_tcp`: TCP 到達性
- `postgres_sql`: SQL 実行可否（`SELECT 1`）
