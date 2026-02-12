"""
`/backend/v1/healthz` のレスポンススキーマ定義

ヘルスチェックで返す最小限のメタ情報（状態・アプリ識別子・時刻・バージョン）
を Pydantic モデルとして定義

設計意図:
- API レスポンスの型安全性の担保
- OpenAPI への明示的なスキーマ反映
- バリデーション責務の API 層への集約
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal

from pydantic import BaseModel, Field


class HealthDependencyCheck(BaseModel):
    """
    外部依存（DB など）向けの個別ヘルスチェック結果。
    """

    name: str = Field(
        ...,
        description="依存先名。",
        examples=["postgres"],
    )
    target: str = Field(
        ...,
        description="チェック対象（host:port など）。",
        examples=["localhost:5432", "(not configured)"],
    )
    status: Literal["ok", "fail", "skipped"] = Field(
        ...,
        description='依存先の状態。("ok" | "fail" | "skipped")',
        examples=["ok"],
    )
    latency_ms: int | None = Field(
        default=None,
        description="TCP接続のレイテンシ(ms)。skipped の場合は null。",
        examples=[12],
    )
    error: str | None = Field(
        default=None,
        description="失敗時のエラー詳細。成功時は null。",
        examples=["timeout"],
    )


class HealthzResponse(BaseModel):
    """
    ヘルスチェック応答モデル。

    サービスが稼働していることを示す `status` と、運用時の識別・監視で利用する
    メタ情報（`app`, `now`, `version`）を保持する。

    Attributes:
        status: サービス状態。正常時は常に `"ok"`。
        app: アプリケーション識別子（サービス名）。
        now: レスポンス生成時点のサーバ時刻（UTC）。
        version: API またはアプリケーションのバージョン。
    """

    status: Literal["ok", "fail"] = Field(
        ...,
        description='サービス状態。依存先チェック失敗時は "fail"。',
        examples=["ok", "fail"],
    )
    app: str = Field(
        ...,
        description="アプリケーション識別子（サービス名）。",
        examples=["3pull-api"],
    )
    now: datetime = Field(
        ...,
        description="サーバ時刻（UTC）。",
        examples=[datetime.now(tz=UTC)],
    )
    version: str = Field(
        ...,
        description="アプリケーションバージョン。",
        examples=["v1"],
    )
    dependencies: list[HealthDependencyCheck] = Field(
        ...,
        description="依存先ごとのヘルスチェック結果一覧。",
    )
