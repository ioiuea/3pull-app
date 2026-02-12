## バックエンドのセットアップと起動（uv）

### 前提
- `uv` がインストールされており、PATH が通っていること。

### 依存関係のインストール
```bash
uv sync
```

### 環境変数（例）
`apps/api/.env` を用意して起動前に読み込まれる想定です（dev 時のみ自動ロード）。
```env
API_LOG_LEVEL=INFO
GUNICORN_WORKERS=2
GUNICORN_THREADS=1
GUNICORN_TIMEOUT=60
GUNICORN_KEEPALIVE=5
```

### 開発起動
```bash
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 本番相当の起動
```bash
uv run gunicorn -k uvicorn.workers.UvicornWorker app.main:app \\
  --bind 0.0.0.0:8000 \\
  --workers ${GUNICORN_WORKERS:-2} \\
  --threads ${GUNICORN_THREADS:-1} \\
  --timeout ${GUNICORN_TIMEOUT:-60} \\
  --keep-alive ${GUNICORN_KEEPALIVE:-5}
```

### 動作確認（ヘルスチェック）
```bash
curl http://localhost:8000/backend/v1/healthz
```
