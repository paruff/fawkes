import logging
import re

from fawkes_common.logging import configure_logging


def bare_root_logger(monkeypatch):
    """basicConfig does nothing when the root logger has handlers. Call from the test body: pytest adds its own after fixtures."""
    monkeypatch.setattr(logging.root, "handlers", [])
    monkeypatch.setattr(logging.root, "level", logging.WARNING)


def test_records_carry_time_logger_level_and_message(monkeypatch, capsys):
    bare_root_logger(monkeypatch)
    configure_logging()

    logging.getLogger("fawkes.example").info("started")

    line = capsys.readouterr().err.strip()
    assert re.fullmatch(r"\d{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d{3} - fawkes\.example - INFO - started", line)


def test_debug_level_can_be_requested(monkeypatch):
    bare_root_logger(monkeypatch)

    configure_logging(logging.DEBUG)

    assert logging.root.level == logging.DEBUG
