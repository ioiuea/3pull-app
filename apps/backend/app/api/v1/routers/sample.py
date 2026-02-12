"""
SWR サンプル用 API ルーター。
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Response

from app.api.v1.schemas.sample import SampleResponse
from app.core.security.auth import ApiTokenPrincipal, get_current_principal
from app.services.sample import build_sample_payload

router = APIRouter(tags=["sample"])


@router.get(
    "/sample",
    summary="Sample",
    response_model=SampleResponse,
    response_model_by_alias=True,
)
async def get_sample(
    response: Response,
    _principal: ApiTokenPrincipal = Depends(get_current_principal),
    q: str = Query(
        default="",
        max_length=30,
        description="タイトル/説明の部分一致検索クエリ。",
    ),
) -> SampleResponse:
    """
    SWR サンプル用の検索結果を返す。
    """
    response.headers["Cache-Control"] = "no-store"
    return SampleResponse.model_validate(build_sample_payload(q))
