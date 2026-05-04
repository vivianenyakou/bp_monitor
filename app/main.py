from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.core.exceptions import BPMonitorException
from app.interfaces.routes import alertes, mesures, patients,auth

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    description="Microservice de suivi de tension artérielle — Clean Architecture",
)

# ── Routes ────────────────────────────────────────────────────────
app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(mesures.router, prefix=settings.api_prefix)
app.include_router(alertes.router, prefix=settings.api_prefix)
app.include_router(patients.router, prefix=settings.api_prefix)

from app.interfaces.routes import alertes, auth, mesures, patients



app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Gestionnaire d'erreurs global ─────────────────────────────────
@app.exception_handler(BPMonitorException)
async def bp_monitor_exception_handler(
    request: Request, exc: BPMonitorException
) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"succes": False, "message": exc.message},
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