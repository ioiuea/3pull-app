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

from app.core.settings.config import get_settings


def build_health_payload() -> dict[str, str | datetime]:
    """
    ヘルスチェック応答の元データを生成する。

    Returns:
        dict[str, str | datetime]:
            API バージョン非依存のヘルス情報。
            具体的なレスポンススキーマへの変換・検証は router 側で
            Pydantic (`HealthzResponse`) により実施する。
    """

    settings = get_settings()
    return {
        "status": "ok",
        "app": settings.service_name,
        "now": datetime.now(tz=UTC),
        "version": settings.api_version,
    }
