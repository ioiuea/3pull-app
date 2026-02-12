# バックエンド（FastAPI）

## 前提要件

- `uv` がインストール済みで、PATH が通っていること

## セットアップ手順

### 1) 環境変数の準備
`.env.example` をコピーして `.env` を作成し、必要な値を編集します。

```bash
cp .env.example .env
```

`apps/backend/.env` を用意して起動前に読み込まれる想定です（dev 時のみ自動ロード）。

```env
API_LOG_LEVEL=INFO
GUNICORN_WORKERS=2
GUNICORN_THREADS=1
GUNICORN_TIMEOUT=60
GUNICORN_KEEPALIVE=5
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/3pull
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
JWT_ISSUER=3pull-web
JWT_AUDIENCE=3pull-api
```

### 2) 依存関係のインストール

```bash
uv sync
```

## 起動方法

### ローカル開発

```bash
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 本番相当の起動

```bash
uv run gunicorn -k uvicorn.workers.UvicornWorker app.main:app \
  --bind 0.0.0.0:8000 \
  --workers ${GUNICORN_WORKERS:-2} \
  --threads ${GUNICORN_THREADS:-1} \
  --timeout ${GUNICORN_TIMEOUT:-60} \
  --keep-alive ${GUNICORN_KEEPALIVE:-5}
```

## 動作確認（ヘルスチェック / JWT 必須）

```bash
curl -H "Authorization: Bearer <api-jwt>" \
  http://localhost:8000/backend/v1/healthz
```

## 動作確認（JWT検証）

Bearer JWT を渡すと、署名検証してユーザー情報を返します。

```bash
curl -H "Authorization: Bearer <api-jwt>" \
  http://localhost:8000/backend/v1/me
```
