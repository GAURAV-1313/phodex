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

AUTH_DURATION = Histogram(
    "phodex_auth_duration_seconds",
    "Auth endpoint duration",
    ["endpoint"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)
TASK_CREATE_DURATION = Histogram(
    "phodex_task_create_duration_seconds",
    "Task creation duration",
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)
TASK_DETAIL_DURATION = Histogram(
    "phodex_task_detail_duration_seconds",
    "Task detail query duration (joins 4 tables)",
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)
DB_POOL_SIZE = Gauge("phodex_db_pool_size", "Current active DB connections")
DB_POOL_IDLE = Gauge("phodex_db_pool_idle", "Idle DB connections in pool")
DB_QUERY_FAILURES = Counter(
    "phodex_db_query_failures_total", "Database query failures", ["operation"]
)
SSE_CONNECTION_DURATION = Histogram(
    "phodex_sse_connection_duration_seconds",
    "SSE connection lifetime",
    buckets=(5.0, 15.0, 30.0, 60.0, 120.0, 300.0, 600.0, 1800.0),
)
RATE_LIMIT_REJECTIONS = Counter(
    "phodex_rate_limit_rejections_total", "Rate limit rejections", ["endpoint"]
)


def metrics_response() -> tuple[bytes, str]:
    return generate_latest(), CONTENT_TYPE_LATEST
