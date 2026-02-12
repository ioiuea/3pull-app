"""
FastAPIアプリのブートストラップ

- Settings（pydantic-settings）をロード
- structlog をJSON出力で初期化
- 公開ルーターは `/backend/<api_version>` 配下に集約（例：/backend/v1）
- 内部プローブ（/livez, /readyz）はアプリ直下にマウント（外部公開から除外）
- アクセスログは AccessLogMiddleware によりJSONで出力
"""

from __future__ import annotations

from fastapi import FastAPI

from app.core.settings import get_settings
from app.core.lifecycle.startup import lifespan
from app.core.logging.middleware import AccessLogMiddleware
from app.api.internal.probes import router as probes_router
from app.api.v1.routers.health import router as health_router


def create_app() -> FastAPI:
    """
    FastAPIアプリケーションを生成して設定する
    """

    settings = get_settings()

    application = FastAPI(
        title=settings.service_name,
        version=settings.api_version,
        lifespan=lifespan,
    )

    # 構造化アクセスログ（Uvicornアクセスログは無効化想定）
    application.add_middleware(AccessLogMiddleware)

    # 公開APIは /backend/<api_version> に集約（例：/backend/v1）
    application.include_router(
        health_router,
        prefix=f"/backend/{application.version}",
    )

    # 内部専用プローブ（公開ルーティングから除外）
    application.include_router(probes_router)

    return application


# ASGI entrypoint
app: FastAPI = create_app()
