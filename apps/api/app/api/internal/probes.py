from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(tags=["probes"])


@router.get("/livez")
def livez() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ok"}
