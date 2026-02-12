"""
ヘルスチェック用ドメインサービス。

- API バージョンに依存しないヘルス判定ロジックを担当する
- 依存先として Postgres の TCP 到達性と SQL 実行可否を確認する
"""

from __future__ import annotations

import time
from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlsplit

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters.network import tcp_ping
from app.core.settings import get_settings


def _host_port_from_url(url: str | None, default_port: int) -> tuple[str, int] | None:
    if not url:
        return None

    parsed = urlsplit(url)
    if not parsed.hostname:
        return None

    try:
        port = parsed.port or default_port
    except ValueError:
        return None

    return parsed.hostname, port


async def _postgres_sql_check(db_session: AsyncSession) -> tuple[bool, int, str | None]:
    """
    Postgres に対して `SELECT 1` を実行して、SQL レベルの接続性を確認する。
    """
    started = time.perf_counter()
    try:
        result = await db_session.execute(text("SELECT 1"))
        value = result.scalar_one_or_none()
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        if value == 1:
            return True, elapsed_ms, None
        return False, elapsed_ms, "unexpected result"
    except Exception as exc:
        elapsed_ms = int((time.perf_counter() - started) * 1000)
        return False, elapsed_ms, str(exc)


async def build_health_payload(db_session: AsyncSession) -> dict[str, Any]:
    """
    ヘルスチェック応答の元データを生成する。
    """
    s = get_settings()
    dependencies: list[dict[str, object]] = []

    pg = _host_port_from_url(s.database_url, 5432)
    if pg:
        ok, ms, err = tcp_ping(pg[0], pg[1])
        dependencies.append(
            {
                "name": "postgres_tcp",
                "target": f"{pg[0]}:{pg[1]}",
                "status": "ok" if ok else "fail",
                "latency_ms": ms,
                "error": err,
            }
        )

        sql_ok, sql_ms, sql_err = await _postgres_sql_check(db_session)
        dependencies.append(
            {
                "name": "postgres_sql",
                "target": "SELECT 1",
                "status": "ok" if sql_ok else "fail",
                "latency_ms": sql_ms,
                "error": sql_err,
            }
        )
    else:
        dependencies.append(
            {
                "name": "postgres_tcp",
                "target": "(not configured)",
                "status": "skipped",
            }
        )
        dependencies.append(
            {
                "name": "postgres_sql",
                "target": "SELECT 1",
                "status": "skipped",
            }
        )

    overall_status = (
        "fail" if any(dep.get("status") == "fail" for dep in dependencies) else "ok"
    )

    return {
        "status": overall_status,
        "app": s.service_name,
        "now": datetime.now(tz=UTC),
        "version": s.api_version,
        "dependencies": dependencies,
    }
