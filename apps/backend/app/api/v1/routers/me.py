"""
認証済みユーザー情報 API ルーター。
"""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.api.v1.schemas.auth import MeResponse
from app.core.security.auth import ApiTokenPrincipal, get_current_principal

router = APIRouter(tags=["auth"])


@router.get(
    "/me",
    summary="Current user",
    response_model=MeResponse,
)
async def get_me(
    principal: ApiTokenPrincipal = Depends(get_current_principal),
) -> MeResponse:
    """
    JWTで認証された現在ユーザー情報を返す。
    """
    return MeResponse(
        user_id=principal.user_id,
        user_email=principal.user_email,
        user_name=principal.user_name,
        email_verified=principal.email_verified,
        active_organization_id=principal.active_organization_id,
        organization_role=principal.organization_role,
        session_expires_at=principal.expires_at,
        token_issuer=principal.issuer,
        token_audience=principal.audience,
    )
