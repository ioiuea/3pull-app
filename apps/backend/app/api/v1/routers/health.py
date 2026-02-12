"""
ヘルスチェック API ルーター。

`/backend/v1/healthz` を提供し、サービスの稼働状態とメタ情報を返却
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters.postgres.session import get_session
from app.api.v1.schemas.health import HealthzResponse
from app.core.security.auth import ApiTokenPrincipal, get_current_principal
from app.services.health import build_health_payload

router = APIRouter(tags=["health"])


@router.get(
    "/healthz",
    summary="Health",
    response_model=HealthzResponse,
)
async def get_healthz(
    _principal: ApiTokenPrincipal = Depends(get_current_principal),
    db_session: AsyncSession = Depends(get_session),
) -> HealthzResponse:
    """
    ヘルスチェック結果を返す。
    """
    return HealthzResponse(**(await build_health_payload(db_session)))
