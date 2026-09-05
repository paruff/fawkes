FROM python:3.13.15-slim

WORKDIR /app

# Install dependencies (pip upgrade fixes CVE-2026-13346, present in the base image's bundled pip)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /usr/local/lib/python3.13/site-packages/pip* \
      /usr/local/lib/python3.13/site-packages/setuptools* \
      /usr/local/lib/python3.13/site-packages/pkg_resources

# Copy application
COPY app/ ./app/
COPY rules/ ./rules/

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
