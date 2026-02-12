# データベース初期化

このディレクトリには PostgreSQL の初期化スクリプトがあります。

## Azure Database for PostgreSQL Flexible Server 向け

これらのスクリプトは、標準的な `PG*` 環境変数で接続する前提です（Azure Flexible Server 互換）。  
新しい環境を作成した初回に一度実行してください。冪等に作られているため、再実行しても安全です。

### 各スクリプトの役割

- `db/postgres/init/run_all.sh`
  - 初期化スクリプトを順番にすべて実行します。

- `db/postgres/init/scripts/001_create_database.sh`
  - デフォルト DB `postgres` に接続し、`PGDATABASE` で指定した DB がなければ作成します。

- `db/postgres/init/scripts/002_create_schema.sh`
  - `PGDATABASE` に接続し、`auth` と `core` スキーマを作成します（未作成時のみ）。

- `db/postgres/init/scripts/003_roles.sh`
  - Web/API 用のロールを作成し、最小権限を付与し、`PUBLIC` 権限を制限します。

- `db/postgres/init/scripts/004_search_path.sh`
  - ロールごとの `search_path` 既定値を設定します。
  - web 用: `auth`
  - api 用: `core,public`

### 実行方法（プロジェクトルートで実行）

#### 0) 必要な環境変数を設定（シェルごとに1回）

```bash
export PGHOST=test-3pull-db.postgres.database.azure.com
export PGUSER=postgresadmin
export PGPORT=5432
export PGDATABASE=threepull
export PGPASSWORD="{your-password}"
export WEB_APP_DB_USER=threepull_web
export API_APP_DB_USER=threepull_api
```

#### 1) 初期化スクリプトを一括実行（通常はこちら）

```bash
bash db/postgres/init/run_all.sh
```

補足:
- `PGDATABASE` は新規作成するデータベース名です。
- DB 作成ステップではデフォルト DB `postgres` に接続して作成します。

#### 2) ステップごとに個別実行（必要時）

##### 2-1) データベース作成

```bash
bash db/postgres/init/scripts/001_create_database.sh
```

##### 2-2) スキーマ作成

```bash
bash db/postgres/init/scripts/002_create_schema.sh
```

##### 2-3) ロール作成・権限設定

```bash
bash db/postgres/init/scripts/003_roles.sh
```

##### 2-4) `search_path` 既定値設定

```bash
bash db/postgres/init/scripts/004_search_path.sh
```

データベース作成後のスキーマ変更は、`auth` は Drizzle、`core` は Alembic で管理してください。
