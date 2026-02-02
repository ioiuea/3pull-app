#!/usr/bin/env bash
set -euo pipefail

# Debug output (always on)
echo "[debug] PGHOST=${PGHOST:-}"
echo "[debug] PGPORT=${PGPORT:-}"
echo "[debug] PGUSER=${PGUSER:-}"
echo "[debug] PGDATABASE=${PGDATABASE:-}"
echo "[debug] WEB_APP_DB_USER=${WEB_APP_DB_USER:-}"
echo "[debug] API_APP_DB_USER=${API_APP_DB_USER:-}"

pause() {
  read -r -p "Press Enter to continue..." _ </dev/tty
}

# Required env checks
missing_env=()
for env_key in PGHOST PGUSER PGPORT PGDATABASE PGPASSWORD WEB_APP_DB_USER API_APP_DB_USER; do
  if [[ -z "${!env_key:-}" ]]; then
    missing_env+=("$env_key")
  fi
done

if (( ${#missing_env[@]} > 0 )); then
  echo "❌ Required environment variables are missing: ${missing_env[*]}" >&2
  echo "Set them and rerun." >&2
  exit 1
fi

# 本スクリプトは Azure Database for PostgreSQL などの外部DBに対して、初期構築時に一度だけ実行します。
# 目的:
# - Web(Next.js) 用:  ${WEB_APP_DB_USER} ・・・ auth スキーマを管理
# - API(FastAPI) 用:  ${API_APP_DB_USER} ・・・ core スキーマを管理
# - 各ロール/スキーマの権限を最小限で付与し、PUBLIC の過剰権限を剥奪
# - すべて idempotent（存在すれば変更しない）

echo "[info] Initializing roles and privileges on database: ${PGDATABASE}"
pause

psql -v ON_ERROR_STOP=1 --username "$PGUSER" --dbname "$PGDATABASE" <<SQL

-- =========================================================
-- 1) ロール作成（存在チェック付き）
-- =========================================================
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${WEB_APP_DB_USER}') THEN
    CREATE ROLE ${WEB_APP_DB_USER} LOGIN PASSWORD '${PGPASSWORD}';
  ELSE
    ALTER ROLE ${WEB_APP_DB_USER} LOGIN PASSWORD '${PGPASSWORD}';
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${API_APP_DB_USER}') THEN
    CREATE ROLE ${API_APP_DB_USER} LOGIN PASSWORD '${PGPASSWORD}';
  ELSE
    ALTER ROLE ${API_APP_DB_USER} LOGIN PASSWORD '${PGPASSWORD}';
  END IF;
END
\$\$;

-- DB 接続権限（最低限）
GRANT CONNECT ON DATABASE ${PGDATABASE} TO ${WEB_APP_DB_USER};
GRANT CONNECT ON DATABASE ${PGDATABASE} TO ${API_APP_DB_USER};

-- =========================================================
-- 2) スキーマ存在前提のハードニング（auth / core）
--    （002_create_schema.sh で作成済み想定。なければエラーにはならない）
-- =========================================================
-- PUBLIC から不要な USAGE/CREATE を外す（auth/core は明示的に利用ロールのみ）
DO \$\$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
    REVOKE ALL ON SCHEMA auth FROM PUBLIC;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'core') THEN
    REVOKE ALL ON SCHEMA core FROM PUBLIC;
  END IF;
END
\$\$;

-- =========================================================
-- 3) Web 用ロール（auth スキーマを管理）
-- =========================================================
DO \$\$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
    -- auth スキーマの利用/作成
    GRANT USAGE, CREATE ON SCHEMA auth TO ${WEB_APP_DB_USER};

    -- 既存オブジェクトへの権限（保険：既にある場合）
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA auth TO ${WEB_APP_DB_USER};
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO ${WEB_APP_DB_USER};

    -- 以後、auth 内で ${WEB_APP_DB_USER} が作成するオブジェクトのデフォルト権限
    ALTER DEFAULT PRIVILEGES FOR ROLE ${WEB_APP_DB_USER} IN SCHEMA auth
      GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${WEB_APP_DB_USER};
    ALTER DEFAULT PRIVILEGES FOR ROLE ${WEB_APP_DB_USER} IN SCHEMA auth
      GRANT USAGE, SELECT ON SEQUENCES TO ${WEB_APP_DB_USER};
  END IF;
END
\$\$;

-- =========================================================
-- 4) API 用ロール（core スキーマを管理 + auth スキーマを参照）
--    ★ ご要望の追記分（USAGE/CREATE とデフォルト権限）を含む
-- =========================================================
DO \$\$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'core') THEN
    -- core スキーマの利用/作成
    GRANT USAGE, CREATE ON SCHEMA core TO ${API_APP_DB_USER};

    -- 既存オブジェクトへの権限（保険：既にある場合）
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO ${API_APP_DB_USER};
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA core TO ${API_APP_DB_USER};

    -- 以後、core 内で ${API_APP_DB_USER} が作成するオブジェクトのデフォルト権限
    ALTER DEFAULT PRIVILEGES FOR ROLE ${API_APP_DB_USER} IN SCHEMA core
      GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${API_APP_DB_USER};
    ALTER DEFAULT PRIVILEGES FOR ROLE ${API_APP_DB_USER} IN SCHEMA core
      GRANT USAGE, SELECT ON SEQUENCES TO ${API_APP_DB_USER};
  END IF;

  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
    -- auth スキーマ上のオブジェクトを FK 参照するための最小権限
    GRANT USAGE ON SCHEMA auth TO ${API_APP_DB_USER};
    GRANT REFERENCES ON ALL TABLES IN SCHEMA auth TO ${API_APP_DB_USER};
    
    -- Workspace export 用に auth スキーマ全体の read-only 権限を付与
    GRANT SELECT ON ALL TABLES IN SCHEMA auth TO ${API_APP_DB_USER};
    ALTER DEFAULT PRIVILEGES FOR ROLE ${WEB_APP_DB_USER} IN SCHEMA auth
      GRANT SELECT ON TABLES TO ${API_APP_DB_USER};

    -- auth 内で Web アプリケーションが作成するオブジェクトへの将来権限
    ALTER DEFAULT PRIVILEGES FOR ROLE ${WEB_APP_DB_USER} IN SCHEMA auth
      GRANT REFERENCES ON TABLES TO ${API_APP_DB_USER};
  END IF;
END
\$\$;

-- =========================================================
-- 5) public スキーマのハードニング（最小権限）
--    ※ public を業務用に使う最小構成（必要な場合のみ）
-- =========================================================
GRANT USAGE ON SCHEMA public TO ${API_APP_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${API_APP_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO ${API_APP_DB_USER};

-- 一般公開ロールの過剰権限を剥奪（base hardening）
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

SQL

echo "----------------------------------------------"
echo "✅ Roles & privileges initialized:"
echo "   - ${WEB_APP_DB_USER} (auth schema)"
echo "   - ${API_APP_DB_USER} (core schema)"
echo "   PUBLIC hardening applied (auth/core/public)."
echo "----------------------------------------------"

echo "[verify] List roles"
pause
psql --username "$PGUSER" --dbname "$PGDATABASE" -x -c "\du+"

echo "[verify] Schema owners"
pause
psql --username "$PGUSER" --dbname "$PGDATABASE" -x -c "SELECT nspname, nspowner::regrole FROM pg_namespace WHERE nspname IN ('auth','core','public');"

echo "[verify] Web role schema privileges (auth)"
pause
psql --username "$PGUSER" --dbname "$PGDATABASE" -x -c "SELECT 'USAGE' AS privilege, has_schema_privilege('${WEB_APP_DB_USER}','auth','USAGE') AS granted UNION ALL SELECT 'CREATE', has_schema_privilege('${WEB_APP_DB_USER}','auth','CREATE');"

echo "[verify] API role schema privileges (core)"
pause
psql --username "$PGUSER" --dbname "$PGDATABASE" -x -c "SELECT 'USAGE' AS privilege, has_schema_privilege('${API_APP_DB_USER}','core','USAGE') AS granted UNION ALL SELECT 'CREATE', has_schema_privilege('${API_APP_DB_USER}','core','CREATE');"
