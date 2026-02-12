"""
ヘルスチェック用ドメインサービス

API バージョン (`api/v1` など)に依存しないドメインロジックを担当
将来 `api/v2` を追加しても service の再利用をしやすくする

設計方針:
- この層では `app/api/v1/schemas` の Pydantic モデルを import しない
- 返却値はプレーンな `dict` とし、HTTP レスポンス形式への確定は router 層に委ねる

Pydantic との責務分離:
- 検証・シリアライズ・OpenAPI 表現は API 層の `response_model` (Pydantic) が担当
- service 層は「どの値を返すか」のみを決定
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlsplit

from app.adapters.network import tcp_ping
from app.core.settings import get_settings


def _host_port_from_url(url: str | None, default_port: int) -> tuple[str, int] | None:
    """
    Extract host and port from DSN-like URL.
    / DSN 形式のURLから host/port を抽出する
    """
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


def build_health_payload() -> dict[str, Any]:
    """
    ヘルスチェック応答の元データを生成する。

    Returns:
        dict[str, Any]:
            API バージョン非依存のヘルス情報。
            具体的なレスポンススキーマへの変換・検証は router 側で
            Pydantic (`HealthzResponse`) により実施する。
    """

    s = get_settings()
    dependencies: list[dict[str, object]] = []

    # Postgres
    pg = _host_port_from_url(s.database_url, 5432)
    if pg:
        ok, ms, err = tcp_ping(pg[0], pg[1])
        dependencies.append(
            {
                "name": "postgres",
                "target": f"{pg[0]}:{pg[1]}",
                "status": "ok" if ok else "fail",
                "latency_ms": ms,
                "error": err,
            }
        )
    else:
        dependencies.append(
            {"name": "postgres", "target": "(not configured)", "status": "skipped"}
        )

    overall_status = (
        "fail"
        if any(dep.get("status") == "fail" for dep in dependencies)
        else "ok"
    )

    return {
        "status": overall_status,
        "app": s.service_name,
        "now": datetime.now(tz=UTC),
        "version": s.api_version,
        "dependencies": dependencies,
    }
