from src.core.service_checker import ServiceChecker, Status

def test_known_service_returns_correct_status():
    checker = ServiceChecker()
    result = checker.get_status("payments")
    assert result.name == "payments"
    assert result.status == Status.healthy

def test_unknown_service_defaults_to_healthy():
    checker = ServiceChecker()
    result = checker.get_status("unknown-service")
    assert result.status == Status.healthy

def test_down_service_returns_correct_message():
    checker = ServiceChecker()
    result = checker.get_status("notifications")
    assert result.status == Status.down
    assert "unreachable" in result.message