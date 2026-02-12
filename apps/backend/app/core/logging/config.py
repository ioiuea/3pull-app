"""
structlogで構造化ログを初期化

- アプリのログをJSONでstdoutへ出力
- Uvicornのアクセス/エラーログは標準ログ伝播に任せる
  （アクセスはUvicorn側で無効化し、別ミドルウェアでJSON出力する推奨構成）
"""

from __future__ import annotations

import logging
import sys
from typing import Final

import structlog

_ALLOWED_LEVELS: Final[set[str]] = {
    "DEBUG",
    "INFO",
    "WARNING",
    "ERROR",
    "CRITICAL",
}


def _coerce_level(level: str) -> int:
    """
    レベル名をloggingレベルに変換する

    Args:
        level: 大文字小文字を区別しないレベル名

    Returns:
        int: loggingモジュールの数値レベル
    """
    upper = level.upper()
    if upper not in _ALLOWED_LEVELS:
        upper = "INFO"
    return getattr(logging, upper, logging.INFO)


def setup_logging(level: str = "INFO") -> None:
    """
    構造化ログを初期化する

    標準ログをstdoutへ設定し、structlogでISO/UTCのJSONに整形する。
    Uvicorn系ロガーは伝播させ、実行時の設定に委ねる。

    Args:
        level: ルートロガーのログレベル
    """
    # 標準ログ設定（重複ハンドラを避ける）
    logging.basicConfig(
        level=_coerce_level(level),
        handlers=[logging.StreamHandler(sys.stdout)],
        force=True,
    )

    # uvicorn系は標準のまま扱う
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        logger = logging.getLogger(name)
        logger.propagate = True

    # structlogのJSON出力設定
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.add_log_level,
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.EventRenamer("event"),
            structlog.processors.JSONRenderer(),
        ],
        # stdlib互換のファクトリで他ライブラリと協調
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Uvicornの標準アクセスログを無効化して二重出力を防ぐ
    ua = logging.getLogger("uvicorn.access")
    ua.handlers.clear()
    ua.propagate = False
    ua.disabled = True


def get_logger(name: str | None = None) -> structlog.stdlib.BoundLogger:
    """
    構造化ロガーを取得する

    Args:
        name: 任意のロガー名

    Returns:
        structlog.stdlib.BoundLogger: 構造化ロガー
    """
    return structlog.get_logger(name or "app")
