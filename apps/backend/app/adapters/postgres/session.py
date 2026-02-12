"""
psycopg v3 を用いた非同期 SQLAlchemy エンジンと FastAPI 依存。

- DATABASE_URL（例: postgresql+psycopg://...）を使用する。
- get_session() は UoW としてトランザクション範囲を提供する。
- 重要: Router/Service では commit()/rollback() を呼ばない。
  トランザクション制御はこの層で一元化する。
"""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.settings.config import get_settings

logger = logging.getLogger(__name__)

# インポート時に DB URL を解決する（未設定なら即時失敗）。
settings = get_settings()
DATABASE_URL: str | None = settings.database_url
if not DATABASE_URL:
    logger.error("DATABASE_URL is not set (e.g. postgresql+psycopg://...)")
    raise RuntimeError("DATABASE_URL is not set")

# 非同期エンジン（psycopg v3）。
engine: AsyncEngine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    echo=False,
    future=True,
)

# セッションファクトリ。
SessionLocal: async_sessionmaker[AsyncSession] = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """
    非同期セッションファクトリを返す。

    戻り値:
        async_sessionmaker[AsyncSession]: セッションファクトリ
    """
    return SessionLocal


async def get_session() -> AsyncIterator[AsyncSession]:
    """
    トランザクション（UoW）内で AsyncSession を yield する FastAPI 依存。

    yield 値:
        AsyncSession: `async with session.begin()` 範囲内のアクティブセッション

    注意:
        - 成功時は commit、例外時は rollback を SQLAlchemy が自動管理する。
        - 上位レイヤーで commit()/rollback() は呼ばない。
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        async with session.begin():  # 成功時 commit / 例外時 rollback
            yield session
