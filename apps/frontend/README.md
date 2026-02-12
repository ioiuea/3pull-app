# フロントエンド（Next.js）

## 前提要件

- pnpm がインストール済みであること
- PostgreSQL クライアント（`psql`）が利用できること
- `npx` が利用できること（未導入の場合は `pnpm dlx` を使用してください）

## セットアップ手順

### 1) 環境変数の準備
`.env.example` をコピーして `.env` を作成し、必要な値を編集します。

```bash
cp .env.example .env
```

### 2) 依存関係のインストール

```bash
pnpm install
```

## データベースマイグレーション（初回セットアップ時のみ実施）

Schema source: `apps/frontend/drizzle/schema.ts`  
Migration output: `apps/frontend/drizzle/migrations/`

マイグレーションの生成:

```bash
npx drizzle-kit generate --name add_auth_models
```

マイグレーションの適用:

```bash
psql "$DATABASE_URL" -f apps/frontend/drizzle/migrations/0000_add_auth_models.sql
```

Notes:
- `generate` は SQL ファイルを生成するだけで、DB には反映しません。
- `push` は DB を直接更新し、マイグレーションファイルは参照しません。

## 起動方法

### ローカル開発

```bash
pnpm dev
```

### 本番相当の起動

```bash
pnpm build
pnpm start
```
