from pydantic import BaseModel
from enum import Enum


class Status(str, Enum):
    healthy = "healthy"
    degraded = "degraded"
    down = "down"


class ServiceStatus(BaseModel):
    name: str
    status: Status
    latency_ms: float
    message: str

