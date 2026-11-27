import logging

from fawkes_common.database import Database
from sqlalchemy import text


def test_session_dependency_yields_a_working_session_and_closes_it():
    database = Database("sqlite://")
    dependency = database.get_db()

    session = next(dependency)
    assert session.execute(text("SELECT 1")).scalar() == 1
    assert session.in_transaction()

    dependency.close()
    assert not session.in_transaction()


def test_engine_options_are_passed_through():
    assert Database("sqlite://", echo=True).engine.echo is True


def test_check_connection_succeeds_against_a_reachable_database():
    assert Database("sqlite://").check_connection() is True


def test_check_connection_logs_why_it_failed(tmp_path, caplog):
    database = Database(f"sqlite:///{tmp_path}/missing/db.sqlite")

    with caplog.at_level(logging.ERROR):
        assert database.check_connection() is False

    assert "unable to open database file" in caplog.text
