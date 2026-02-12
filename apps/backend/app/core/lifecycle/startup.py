"""
アプリ起動時のライフサイクル管理

- 起動時にログ初期化を行い、起動・終了ログを出力する
"""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.logging.config import get_logger, setup_logging
from app.core.settings import get_settings

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """
    アプリケーションのlifespan管理
    """

    settings = get_settings()
    setup_logging(level=settings.api_log_level)

    logger.info(
        "api_startup",
        version=settings.api_version,
        service=settings.service_name,
    )
    try:
        yield
    finally:
        logger.info("api_shutdown", service=settings.service_name)
