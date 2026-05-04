from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["Santé"])
async def health_check():
    return {
        "status": "ok",
        "service": settings.app_name,
        "version": settings.app_version,
        "mode": settings.app_mode,
        "message": "Bienvenue sur Auto-Mesure de Tension Arterielle 🚀"
    }