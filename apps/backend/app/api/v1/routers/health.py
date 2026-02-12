"""
ヘルスチェック API ルーター。

`/backend/v1/healthz` を提供し、サービスの稼働状態とメタ情報を返却

責務:
- HTTP エンドポイント定義
- response_model によるレスポンス明示
- service 層が返すデータの API スキーマへの変換
"""

from __future__ import annotations

from fastapi import APIRouter

from app.api.v1.schemas.health import HealthzResponse
from app.services.health import build_health_payload

router = APIRouter(tags=["health"])


@router.get(
    "/healthz",
    summary="Health",
    response_model=HealthzResponse,
)
def get_healthz() -> HealthzResponse:
    """
    ヘルスチェック結果を返す。

    Returns:
        HealthzResponse:
            稼働状態 (`status`) と、アプリ識別子・時刻・バージョンを含む
            API v1 のレスポンス。
    """
    return HealthzResponse(**build_health_payload())
