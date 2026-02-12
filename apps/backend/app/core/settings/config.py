"""
FastAPI向けアプリ設定ローダ

- pydantic-settingsで環境変数を読み込む
- ローカル開発ではプロジェクトルート(apps/backend/.env)を用意すれば読み込む
- 本番では環境変数注入のみを前提とする
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


# ---- dotenv（存在時に読み込み） ---------------------------------------------

def _load_dotenv_if_present(root_env_path: Path) -> None:
    """
    `.env` が存在する場合のみ読み込む

    次の場合は黙って処理を終了する:
      - python-dotenv未導入
      - .envが存在しない

    Args:
        root_env_path: apps/backend/.env への絶対パス
    """
    if not root_env_path.exists():
        return
    try:
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        # 本番や最小構成ではdotenv未導入でも問題ない
        return
    # 既存の環境変数は上書きしない
    load_dotenv(dotenv_path=root_env_path, override=False)


# apps/backend/app/settings/config.py から 3つ上( apps/backend/ )
_ROOT_ENV: Path = Path(__file__).resolve().parents[3] / ".env"
_load_dotenv_if_present(_ROOT_ENV)


# ---- Settings model --------------------------------------------------------

class AppSettings(BaseSettings):
    """
    環境変数から解決されるアプリ設定
    """

    # ---- App ----
    api_version: str = Field(
        default="v1",
        validation_alias="API_VERSION",
    )

    api_log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = Field(
        default="INFO",
        validation_alias="API_LOG_LEVEL",
    )

    service_name: str = Field(
        default="3pull-api",
        validation_alias="SERVICE_NAME",
    )

    # ---- Ports ----
    api_port: int = Field(
        default=8000,
        validation_alias="API_PORT",
    )

    # ---- Databases ----
    database_url: str | None = Field(
        default=None,
        validation_alias="DATABASE_URL",
    )

    model_config = SettingsConfigDict(
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache(maxsize=1)
def get_settings() -> AppSettings:
    """
    LRUキャッシュで単一化した設定を取得する

    Returns:
        AppSettings: 読み込み済み設定インスタンス
    """
    # NOTE:
    # 必須値は実行時に解決されるため、ここでは単純に構築する
    return AppSettings()  # type: ignore[call-arg]
