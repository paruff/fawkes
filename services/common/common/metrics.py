"""Prometheus metrics helpers for Fawkes platform services."""

from fastapi import FastAPI
from prometheus_client import make_asgi_app


def mount_metrics(app: FastAPI, path: str = "/metrics") -> None:
    """Mount Prometheus metrics endpoint on a FastAPI application.

    Args:
        app: The FastAPI application instance.
        path: The path to mount the metrics endpoint. Defaults to "/metrics".
    """
    metrics_app = make_asgi_app()
    app.mount(path, metrics_app)
