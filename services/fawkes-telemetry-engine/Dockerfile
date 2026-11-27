# Build from services/ so the image can copy common/ (ADR-039):
#   docker build -f services/fawkes-telemetry-engine/Dockerfile services/
FROM python:3.13.14-slim AS builder

WORKDIR /app
COPY fawkes-telemetry-engine/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.13.14-slim

RUN useradd --create-home --uid 10001 appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local
COPY common/fawkes_common ./fawkes_common
COPY fawkes-telemetry-engine/app ./app

# Numeric, so Kubernetes runAsNonRoot can verify it.
USER 10001
ENV PATH=/home/appuser/.local/bin:$PATH

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
