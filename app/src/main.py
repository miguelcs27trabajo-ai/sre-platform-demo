from fastapi import FastAPI
from src.api.routes import router

app = FastAPI(
    title="SRE Platform Demo",
    description="Service health and observability API",
    version="0.1.0",
)

app.include_router(router)