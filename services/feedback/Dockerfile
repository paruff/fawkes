# Multi-stage Dockerfile for Feedback Service
# Stage 1: Build
FROM python:3.12-slim AS build
WORKDIR /app

# Update packages for security
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim
WORKDIR /app

# Update packages for security
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN addgroup --gid 65534 appuser && \
    adduser --uid 65534 --gid 65534 --disabled-password --gecos "" appuser

# Copy installed packages from build stage
COPY --from=build /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

# Copy application code
COPY app ./app

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python -c "import socket; sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM); result = sock.connect_ex(('localhost', 8000)); exit(0 if result == 0 else 1)"

# Run application
CMD uvicorn app.main:app --host 0.0.0.0 --port 8000
