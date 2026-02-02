# Database Initialization

This directory contains initialization scripts for PostgreSQL.

## Azure Database for PostgreSQL Flexible Server

These scripts assume you connect via standard `PG*` environment variables (Azure Flexible Server compatible).
Run them once during the initial setup of a new environment (they are idempotent, so re-running is safe).

### What each script does

- `db/postgres/init/run_all.sh`:
  - Runs all initialization scripts in order.

- `db/postgres/init/scripts/001_create_database.sh`:
  - Connects to the default `postgres` database and creates the database specified by `PGDATABASE` if it does not exist.
- `db/postgres/init/scripts/002_create_schema.sh`:
  - Connects to `PGDATABASE` and creates `auth` and `core` schemas if they do not exist.
- `db/postgres/init/scripts/003_roles.sh`:
  - Creates the Web/API roles, grants minimum privileges, and hardens `PUBLIC` privileges.
- `db/postgres/init/scripts/004_search_path.sh`:
  - Sets per-role `search_path` defaults for `auth` (web) and `core,public` (api).

### Usage (run from the project root)

#### 0) Set required environment variables (run once per shell)

```bash
export PGHOST=test-3pull-db.postgres.database.azure.com
export PGUSER=postgresadmin
export PGPORT=5432
export PGDATABASE=threepull
export PGPASSWORD="{your-password}"
export WEB_APP_DB_USER=threepull_web
export API_APP_DB_USER=threepull_api
```

#### 1) Run all initialization scripts (run once)

```bash
bash db/postgres/init/run_all.sh
```

Notes:
- `PGDATABASE` is the name of the new database to create.
- The script connects to the default database `postgres` for creation.

#### 2) Run steps individually (optional)

##### 2-1) Create the database (run once)

```bash
bash db/postgres/init/scripts/001_create_database.sh
```

##### 2-2) Create schemas (run once)

```bash
bash db/postgres/init/scripts/002_create_schema.sh
```

##### 2-3) Create roles (run once)

```bash
bash db/postgres/init/scripts/003_roles.sh
```

##### 2-4) Set search_path defaults (run once)

```bash
bash db/postgres/init/scripts/004_search_path.sh
```

After the database is created, manage schema changes via Prisma (auth schema) and Alembic (core schema).
