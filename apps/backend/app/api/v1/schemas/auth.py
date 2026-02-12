from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class MeResponse(BaseModel):
    user_id: str
    user_email: str | None
    user_name: str | None
    email_verified: bool | None
    active_organization_id: str | None
    organization_role: str | None
    session_expires_at: datetime
    token_issuer: str | None
    token_audience: str | list[str] | None
