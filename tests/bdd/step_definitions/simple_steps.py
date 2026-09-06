"""Step definitions for the simple smoke feature (pytest-bdd).

Verifies the pytest-bdd harness itself is wired correctly.
"""

from __future__ import annotations

from pytest_bdd import given, scenarios, then, when

scenarios("../features/simple.feature")


@given("I have a working setup")
def step_given_working_setup():
    """Confirm the BDD harness is importable."""


@when("I run a test")
def step_when_run_test():
    """Run a test."""


@then("it should pass")
def step_then_it_passes():
    """Assert the test passes."""
    assert True
