from app.api.v1.routers.health import router as health_router
from app.api.v1.routers.sample import router as sample_router

__all__ = ["health_router", "sample_router"]
