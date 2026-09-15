"""Shared middleware for Fawkes platform services."""

from typing import List

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


def add_cors_middleware(
    app: FastAPI,
    origins: list[str] | None = None,
    allow_credentials: bool = True,
    allow_methods: list[str] | None = None,
    allow_headers: list[str] | None = None,
) -> None:
    """Add CORS middleware to a FastAPI application.

    Args:
        app: The FastAPI application instance.
        origins: Allowed origins. Defaults to ["*"].
        allow_credentials: Whether to allow credentials.
        allow_methods: Allowed HTTP methods. Defaults to ["*"].
        allow_headers: Allowed headers. Defaults to ["*"].
    """
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins or ["*"],
        allow_credentials=allow_credentials,
        allow_methods=allow_methods or ["*"],
        allow_headers=allow_headers or ["*"],
    )
