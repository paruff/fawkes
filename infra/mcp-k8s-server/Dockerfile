# Minimal image for FastAPI + Kubernetes client
FROM python:3.13.14-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY mcp_k8s_server.py /app/mcp_k8s_server.py

# Run as non-root. UID/GID 1000 matches the k8s deployment securityContext
RUN groupadd --gid 1000 app \
    && useradd --uid 1000 --gid app --no-create-home --shell /usr/sbin/nologin app \
    && chown -R app:app /app

USER app
EXPOSE 8080
CMD ["uvicorn","mcp_k8s_server:app","--host","0.0.0.0","--port","8080"]
