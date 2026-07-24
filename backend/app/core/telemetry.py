from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from app.core.config import Settings


def instrument_fastapi(app: FastAPI) -> None:
    """Register FastAPI middleware before the application lifespan begins."""
    FastAPIInstrumentor.instrument_app(app)


def configure_runtime_telemetry(settings: Settings, engine: object) -> None:
    """Configure optional exporters and runtime integrations during startup."""

    if settings.otel_exporter_otlp_endpoint:
        provider = TracerProvider(resource=Resource.create({"service.name": "phodex-backend"}))
        provider.add_span_processor(
            BatchSpanProcessor(OTLPSpanExporter(endpoint=settings.otel_exporter_otlp_endpoint))
        )
        trace.set_tracer_provider(provider)

    SQLAlchemyInstrumentor().instrument(engine=engine)
    RedisInstrumentor().instrument()
