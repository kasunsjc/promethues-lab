"""
Sample Flask web application instrumented with OpenTelemetry.

Generates traces, metrics, and logs and exports them via OTLP to the
OpenTelemetry Collector. The collector pipeline forwards logs to Loki,
metrics to Prometheus, and traces to the debug exporter (visible in the
collector's container logs).
"""
import logging
import os
import random
import time

from flask import Flask, jsonify, request

# ── OpenTelemetry SDK ────────────────────────────────────────────────
from opentelemetry import trace, metrics
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry._logs import set_logger_provider

# OTLP exporters (gRPC)
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter

# Auto-instrumentations
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# ── Configuration ────────────────────────────────────────────────────
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "sample-webapp")
OTLP_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317")

resource = Resource.create(
    {
        "service.name": SERVICE_NAME,
        "service.version": "1.0.0",
        "deployment.environment": os.getenv("ENVIRONMENT", "lab"),
    }
)

# ── Tracing setup ────────────────────────────────────────────────────
tracer_provider = TracerProvider(resource=resource)
tracer_provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True))
)
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# ── Metrics setup ────────────────────────────────────────────────────
metric_reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=OTLP_ENDPOINT, insecure=True),
    export_interval_millis=10000,
)
meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)
meter = metrics.get_meter(__name__)

request_counter = meter.create_counter(
    name="webapp_requests_total",
    description="Total HTTP requests handled by the sample webapp",
    unit="1",
)
request_latency = meter.create_histogram(
    name="webapp_request_duration_seconds",
    description="Request handler duration",
    unit="s",
)

# ── Logging setup (logs → OTLP → Collector → Loki) ──────────────────
logger_provider = LoggerProvider(resource=resource)
logger_provider.add_log_record_processor(
    BatchLogRecordProcessor(OTLPLogExporter(endpoint=OTLP_ENDPOINT, insecure=True))
)
set_logger_provider(logger_provider)

otel_handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    handlers=[logging.StreamHandler(), otel_handler],
)
log = logging.getLogger("sample-webapp")

# ── Flask app ────────────────────────────────────────────────────────
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()


def _record(route: str, started: float) -> None:
    elapsed = time.time() - started
    request_counter.add(1, {"route": route})
    request_latency.record(elapsed, {"route": route})


@app.route("/")
def index():
    started = time.time()
    log.info("index page requested from %s", request.remote_addr)
    with tracer.start_as_current_span("render-index") as span:
        span.set_attribute("app.page", "index")
        time.sleep(random.uniform(0.01, 0.05))
        _record("/", started)
        return jsonify(
            service=SERVICE_NAME,
            message="Hello from the OTel-instrumented sample webapp!",
            endpoints=["/", "/work", "/error", "/chain", "/healthz"],
        )


@app.route("/work")
def work():
    """Simulate a small unit of work with a child span."""
    started = time.time()
    with tracer.start_as_current_span("do-work") as span:
        steps = random.randint(2, 5)
        span.set_attribute("work.steps", steps)
        for i in range(steps):
            with tracer.start_as_current_span(f"step-{i}"):
                time.sleep(random.uniform(0.02, 0.08))
        log.info("completed work with %d steps", steps)
        _record("/work", started)
        return jsonify(status="ok", steps=steps)


@app.route("/chain")
def chain():
    """Make an outbound HTTP call to demonstrate trace propagation."""
    import requests as http_requests

    started = time.time()
    target = os.getenv("CHAIN_TARGET", "http://nginx:80/")
    with tracer.start_as_current_span("chain-call") as span:
        span.set_attribute("http.target", target)
        try:
            resp = http_requests.get(target, timeout=2)
            span.set_attribute("http.status_code", resp.status_code)
            log.info("chain call to %s returned %d", target, resp.status_code)
            _record("/chain", started)
            return jsonify(target=target, status=resp.status_code)
        except Exception as exc:  # noqa: BLE001
            span.record_exception(exc)
            log.error("chain call failed: %s", exc)
            _record("/chain", started)
            return jsonify(target=target, error=str(exc)), 502


@app.route("/error")
def error():
    """Always raise; useful for verifying error spans and ERROR logs."""
    started = time.time()
    log.warning("about to raise a deliberate error")
    _record("/error", started)
    with tracer.start_as_current_span("boom") as span:
        try:
            raise RuntimeError("Deliberate sample error for tracing demo")
        except RuntimeError as exc:
            span.record_exception(exc)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(exc)))
            log.exception("handler raised")
            return jsonify(error=str(exc)), 500


@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    log.info("starting %s, exporting OTLP to %s", SERVICE_NAME, OTLP_ENDPOINT)
    app.run(host="0.0.0.0", port=5000)
