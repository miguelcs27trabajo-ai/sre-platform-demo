import random
from src.models.service import ServiceStatus, Status


class ServiceChecker:
    """
    Simula el estado de servicios.
    En fases posteriores esto consultará Prometheus real.
    """

    KNOWN_SERVICES = {
        "payments": Status.healthy,
        "auth": Status.healthy,
        "inventory": Status.degraded,
        "notifications": Status.down,
    }

    def get_status(self, name: str) -> ServiceStatus:
        status = self.KNOWN_SERVICES.get(name, Status.healthy)
        return ServiceStatus(
            name=name,
            status=status,
            latency_ms=round(random.uniform(10, 500), 2),
            message=self._message(status),
        )

    def _message(self, status: Status) -> str:
        messages = {
            Status.healthy: "Service operating normally",
            Status.degraded: "Elevated latency detected",
            Status.down: "Service unreachable",
        }
        return messages[status]