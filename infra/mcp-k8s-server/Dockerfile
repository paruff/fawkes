# Minimal image for FastAPI + Kubernetes client
FROM python:3.11-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY mcp_k8s_server.py /app/mcp_k8s_server.py
EXPOSE 8080
CMD ["uvicorn","mcp_k8s_server:app","--host","0.0.0.0","--port","8080"]
