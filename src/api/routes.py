from fastapi import APIRouter
from src.core.service_checker import ServiceChecker
from src.models.service import ServiceStatus


router = APIRouter()
checker = ServiceChecker()

@router.get("/health")
async def health():
    return {"status": "ok"}

@router.get("/services/{name}/status", response_model=ServiceStatus)
async def get_service_status(name: str):
    return checker.get_status(name)