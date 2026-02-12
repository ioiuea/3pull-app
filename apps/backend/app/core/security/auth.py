"""
API保護で使うJWT認証関数。
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JOSEError, JWTError, jwt

from app.core.settings import get_settings

bearer_scheme = HTTPBearer(auto_error=False)
JWT_ALGORITHM = "RS256"


@dataclass(frozen=True, slots=True)
class ApiTokenPrincipal:
    user_id: str
    user_email: str | None
    user_name: str | None
    email_verified: bool | None
    active_organization_id: str | None
    organization_role: str | None
    expires_at: datetime
    issuer: str | None
    audience: str | list[str] | None


def unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def _to_datetime(value: Any) -> datetime:
    if not isinstance(value, (int, float)):
        raise unauthorized("Invalid token payload")
    return datetime.fromtimestamp(value, tz=UTC)


def _decode_api_token(token: str) -> dict[str, Any]:
    settings = get_settings()
    if not settings.jwt_public_key:
        raise RuntimeError("JWT_PUBLIC_KEY is not set")
    public_key = settings.jwt_public_key.replace("\\n", "\n").strip()

    options = {"verify_aud": bool(settings.jwt_audience)}

    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=[JWT_ALGORITHM],
            issuer=settings.jwt_issuer,
            audience=settings.jwt_audience,
            options=options,
        )
    except JWTError as exc:
        raise unauthorized("Invalid or expired token") from exc
    except JOSEError as exc:
        # 署名鍵フォーマット不正など、トークン自体ではなくサーバ設定の不備。
        raise RuntimeError("JWT verification key is invalid") from exc

    if not isinstance(payload, dict):
        raise unauthorized("Invalid token payload")
    return payload


async def get_current_principal(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> ApiTokenPrincipal:
    if credentials is None:
        raise unauthorized("Missing Authorization credentials")

    if (credentials.scheme or "").lower() != "bearer":
        raise unauthorized("Invalid authentication scheme")

    payload = _decode_api_token(credentials.credentials)

    subject = payload.get("sub")
    if not isinstance(subject, str) or not subject.strip():
        raise unauthorized("Invalid token payload")

    expires_at = _to_datetime(payload.get("exp"))

    audience = payload.get("aud")
    if audience is not None and not isinstance(audience, (str, list)):
        raise unauthorized("Invalid token payload")

    return ApiTokenPrincipal(
        user_id=subject,
        user_email=payload.get("email")
        if isinstance(payload.get("email"), str)
        else None,
        user_name=payload.get("name") if isinstance(payload.get("name"), str) else None,
        email_verified=(
            payload.get("email_verified")
            if isinstance(payload.get("email_verified"), bool)
            else None
        ),
        active_organization_id=(
            payload.get("active_organization_id")
            if isinstance(payload.get("active_organization_id"), str)
            else None
        ),
        organization_role=(
            payload.get("organization_role")
            if isinstance(payload.get("organization_role"), str)
            else None
        ),
        expires_at=expires_at,
        issuer=payload.get("iss") if isinstance(payload.get("iss"), str) else None,
        audience=audience,
    )
