"""SQLAlchemy engine and session handling."""

import logging
from collections.abc import Generator
from typing import Any

from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

logger = logging.getLogger(__name__)


class Database:
    """One engine and its session factory. Each monolith creates its own; nothing is global here."""

    def __init__(self, url: str, **engine_options: Any) -> None:
        options = {"pool_pre_ping": True, "pool_recycle": 3600, **engine_options}
        self.engine = create_engine(url, **options)
        self.session_factory = sessionmaker(autoflush=False, bind=self.engine)

    def get_db(self) -> Generator[Session, None, None]:
        """FastAPI dependency.

        Yields:
            A session that is closed after the request.
        """
        with self.session_factory() as session:
            yield session

    def check_connection(self) -> bool:
        """Return whether the database answers a query, logging the reason when it does not."""
        try:
            with self.engine.connect() as connection:
                connection.execute(text("SELECT 1"))
        except SQLAlchemyError:
            logger.exception("Database connection check failed")
            return False
        return True
