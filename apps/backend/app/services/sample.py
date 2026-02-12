"""
SWR サンプル向けの検索データ生成サービス。
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TypedDict


class SampleItemPayload(TypedDict):
    id: str
    title: str
    detail: str


class SamplePayload(TypedDict):
    query: str
    items: list[SampleItemPayload]
    generated_at: datetime


ITEMS: list[SampleItemPayload] = [
    {
        "id": "state",
        "title": "Zustand state",
        "detail": "A tiny store can power shared UI state without prop drilling.",
    },
    {
        "id": "schema",
        "title": "Zod schemas",
        "detail": "Runtime validation keeps client/server data in sync.",
    },
    {
        "id": "fetch",
        "title": "SWR data fetching",
        "detail": "Built-in caching keeps the UI responsive.",
    },
    {
        "id": "ui",
        "title": "Composable UI",
        "detail": "Mix stores, schemas, and fetchers for fast iteration.",
    },
]


def build_sample_payload(query: str) -> SamplePayload:
    """
    クエリで絞り込んだサンプルデータを返す。
    """
    q = query.strip()
    lowered = q.lower()

    filtered_items = (
        ITEMS
        if not lowered
        else [
            item
            for item in ITEMS
            if lowered in item["title"].lower() or lowered in item["detail"].lower()
        ]
    )

    return {
        "query": q,
        "items": filtered_items,
        "generated_at": datetime.now(tz=UTC),
    }
