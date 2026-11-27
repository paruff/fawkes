"""One log line format for every service."""

import logging

LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"


def configure_logging(level: int = logging.INFO) -> None:
    """Configure the root logger. Does nothing if the process has already configured it."""
    logging.basicConfig(level=level, format=LOG_FORMAT)
