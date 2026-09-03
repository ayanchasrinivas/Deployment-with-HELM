import os
import logging
import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg
from prometheus_client import Counter, Histogram, make_asgi_app

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='{"ts":"%(asctime)s","level":"%(levelname)s","msg":"%(message)s"}',
)
log = logging.getLogger("pricing")

APP_VERSION = os.getenv("APP_VERSION", "dev")
DB_DSN = os.getenv("DB_DSN", "")
BASE_MARKUP = float(os.getenv("BASE_MARKUP", "1.15"))

REQUESTS = Counter("pricing_requests_total", "Total price requests", ["status"])
LATENCY = Histogram("pricing_latency_seconds", "Price computation latency")

app = FastAPI(title="pricing-svc", version=APP_VERSION)
app.mount("/metrics", make_asgi_app())

_ready = False


class PriceRequest(BaseModel):
    sku: str
    quantity: int = 1


@app.on_event("startup")
def startup() -> None:
    """Deliberately slow start so you can watch readiness gating in action."""
    global _ready
    delay = int(os.getenv("STARTUP_DELAY_SECONDS", "5"))
    log.info(f"warming up for {delay}s, version={APP_VERSION}")
    time.sleep(delay)
    _ready = True
    log.info("ready")


@app.get("/healthz")
def healthz():
    # Liveness: is the process wedged? Cheap, no dependencies.
    return {"status": "alive", "version": APP_VERSION}


@app.get("/readyz")
def readyz():
    # Readiness: can I serve traffic? Checks dependencies.
    if not _ready:
        raise HTTPException(status_code=503, detail="warming up")
    if DB_DSN:
        try:
            with psycopg.connect(DB_DSN, connect_timeout=2) as conn:
                conn.execute("SELECT 1")
        except Exception as e:
            log.warning(f"db not reachable: {e}")
            raise HTTPException(status_code=503, detail="db unavailable")
    return {"status": "ready"}


@app.post("/price")
@LATENCY.time()
def price(req: PriceRequest):
    if req.quantity <= 0:
        REQUESTS.labels(status="error").inc()
        raise HTTPException(status_code=400, detail="quantity must be positive")
    base = sum(ord(c) for c in req.sku) / 10.0
    total = round(base * req.quantity * BASE_MARKUP, 2)
    REQUESTS.labels(status="ok").inc()
    log.info(f"priced sku={req.sku} qty={req.quantity} total={total}")
    return {"sku": req.sku, "quantity": req.quantity, "total": total, "version": APP_VERSION}