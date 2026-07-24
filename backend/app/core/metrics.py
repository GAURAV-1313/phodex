from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

HTTP_REQUESTS = Counter("phodex_http_requests_total", "HTTP requests", ["method", "path", "status"])
HTTP_DURATION = Histogram(
    "phodex_http_request_duration_seconds", "HTTP request duration", ["method", "path"]
)
TASK_TRANSITIONS = Counter("phodex_task_transitions_total", "Task state transitions", ["status"])
TASK_DURATION = Histogram(
    "phodex_task_execution_duration_seconds", "Task execution duration", ["outcome"]
)
SSE_CONNECTIONS = Gauge("phodex_sse_connections", "Open task SSE connections")
REDIS_PUBLISH_FAILURES = Counter("phodex_redis_publish_failures_total", "Redis publish failures")


def metrics_response() -> tuple[bytes, str]:
    return generate_latest(), CONTENT_TYPE_LATEST
