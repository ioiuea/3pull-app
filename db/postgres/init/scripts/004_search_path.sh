#!/usr/bin/env bash
set -euo pipefail

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

echo "----------------------------------------------"
echo "Setting per-role search_path defaults on database '${PGDATABASE}'..."
echo "  - ${WEB_APP_DB_USER} => search_path=auth"
echo "  - ${API_APP_DB_USER} => search_path=core,public"
echo "----------------------------------------------"
pause

# ロールごと・DBごとに search_path を固定
psql -v ON_ERROR_STOP=1 --username "$PGUSER" --dbname "$PGDATABASE" <<SQL
-- ロール '${WEB_APP_DB_USER}' : auth を最優先に
ALTER ROLE ${WEB_APP_DB_USER} IN DATABASE ${PGDATABASE}
  SET search_path = auth;

-- ロール '${API_APP_DB_USER}' : core を最優先、public をフォールバックに
ALTER ROLE ${API_APP_DB_USER} IN DATABASE ${PGDATABASE}
  SET search_path = core, public;
SQL

# 設定確認（pg_db_role_setting を人間が読みやすく）
psql --username "$PGUSER" --dbname "$PGDATABASE" -v ON_ERROR_STOP=1 -tAc "
  SELECT r.rolname AS role,
         d.datname AS db,
         regexp_replace(s.setconfig::text, '^{|}$', '') AS setconfig
  FROM pg_db_role_setting s
  JOIN pg_roles r     ON r.oid = s.setrole
  JOIN pg_database d  ON d.oid = s.setdatabase
  WHERE r.rolname IN ('${WEB_APP_DB_USER}', '${API_APP_DB_USER}')
    AND d.datname = '${PGDATABASE}'
  ORDER BY r.rolname;
" | sed 's/^/  */'

echo "----------------------------------------------"
echo "✅ search_path defaults configured."
echo "   - ${WEB_APP_DB_USER} -> auth"
echo "   - ${API_APP_DB_USER} -> core,public"
echo "----------------------------------------------"

echo "[verify] Per-role search_path settings"
pause
psql --username "$PGUSER" --dbname "$PGDATABASE" -x -c "SELECT r.rolname AS role, d.datname AS db, regexp_replace(s.setconfig::text, '^{|}$', '') AS setconfig FROM pg_db_role_setting s JOIN pg_roles r ON r.oid = s.setrole JOIN pg_database d ON d.oid = s.setdatabase WHERE r.rolname IN ('${WEB_APP_DB_USER}', '${API_APP_DB_USER}') AND d.datname='${PGDATABASE}' ORDER BY r.rolname;"

echo "[verify] Effective search_path as ${WEB_APP_DB_USER}"
pause
PGPASSWORD="$PGPASSWORD" psql --username "${WEB_APP_DB_USER}" --dbname "$PGDATABASE" -x -c "SHOW search_path;"

echo "[verify] Effective search_path as ${API_APP_DB_USER}"
pause
PGPASSWORD="$PGPASSWORD" psql --username "${API_APP_DB_USER}" --dbname "$PGDATABASE" -x -c "SHOW search_path;"
