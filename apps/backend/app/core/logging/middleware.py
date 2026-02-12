"""
HTTPアクセスログを構造化JSONで出力するミドルウェア

- 概要: アクセスログをJSON形式で1リクエストごとに出力する
- Uvicorn標準のアクセスログは抑止し、本ミドルウェアの出力を正とする
- 期待フォーマット（1行JSONの例）
  {
    "timestamp":"...",
    "level":"INFO",
    "event":"uvicorn.access",
    "client_addr":"127.0.0.1",
    "path":"/api/v1/healthz",
    "status_code":200,
    "method":"GET",
    "latency_ms":1.23
  }
"""

from __future__ import annotations

import time
from typing import Final

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging.config import get_logger

# アクセスログ専用ロガー
logger = get_logger("access")


# 既存期待値との互換のためイベント名を固定
_EVENT_NAME: Final[str] = "uvicorn.access"


class AccessLogMiddleware(BaseHTTPMiddleware):
    """
    リクエスト/レスポンスごとにJSONのアクセスログを出力する
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        """
        リクエストを処理し、レスポンス確定時にログを出力する

        Args:
            request: 受信したHTTPリクエスト
            call_next: 次ハンドラを呼び出すコールバック

        Returns:
            Response: 応答
        """
        started = time.perf_counter()
        client = request.client.host if request.client else "-"
        method = request.method
        path = request.url.path

        try:
            response = await call_next(request)
            status = response.status_code
        except Exception:
            # 例外時は500として記録し、再送出する
            status = 500
            raise
        finally:
            elapsed_ms = (time.perf_counter() - started) * 1000.0
            logger.info(
                _EVENT_NAME,
                client_addr=client,
                path=path,
                status_code=status,
                method=method,
                latency_ms=round(elapsed_ms, 2),
            )

        return response
