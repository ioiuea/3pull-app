"""
`/backend/v1/sample` のレスポンススキーマ定義。
"""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class SampleItem(BaseModel):
    """
    サンプル表示に使う単一アイテム。
    """

    id: str = Field(..., description="アイテム識別子。", examples=["state"])
    title: str = Field(
        ...,
        description="アイテムのタイトル。",
        examples=["Zustand state"],
    )
    detail: str = Field(
        ...,
        description="アイテムの説明文。",
        examples=["A tiny store can power shared UI state without prop drilling."],
    )


class SampleResponse(BaseModel):
    """
    SWR サンプル API の応答モデル。
    """

    query: str = Field(..., description="検索クエリ（最大30文字）。", examples=["zod"])
    items: list[SampleItem] = Field(..., description="検索結果の一覧。")
    generated_at: datetime = Field(
        ...,
        serialization_alias="generatedAt",
        description="レスポンス生成時刻（UTC）。",
    )
