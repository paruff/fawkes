"""
Step definitions for DORA Change Failure Rate calculation (#1947).

Deliberately independent of any live cluster or DevLake instance - uses
fixture deployment/incident counts and a small local re-implementation of
DORA's own Change Failure Rate formula (failed deployments / total
deployments over a window). The real, authoritative calculation lives
inside DevLake's own `dora` plugin (a third-party black box we don't
implement) once the webhook pipeline (#1919, #1944, #1945) is live; this
test verifies the formula itself is correct in isolation, not DevLake's
internals.
"""

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/dora-change-failure-rate-calculation.feature")


class ChangeFailureRateContext:
    def __init__(self):
        self.total_deployments: int = 0
        self.failed_deployments: int = 0
        self.result: float | None = None
        self.no_data: bool = False


_ctx = ChangeFailureRateContext()


def calculate_change_failure_rate(total_deployments: int, failed_deployments: int) -> float | None:
    """DORA's Change Failure Rate: failed deployments / total deployments, as a percentage.

    Returns None when there are no deployments in the window - there is no
    meaningful rate to report, and dividing by zero would either crash or
    (worse) silently produce a misleading 0%/100% value.
    """
    if total_deployments == 0:
        return None
    return round((failed_deployments / total_deployments) * 100, 1)


@given(parsers.parse("{total:d} deployments were recorded in the reporting window"))
def deployments_recorded(total):
    _ctx.total_deployments = total


@given(parsers.parse("{failed:d} of those deployments were followed by a production incident"))
def deployments_followed_by_incident(failed):
    _ctx.failed_deployments = failed


@when("the Change Failure Rate is calculated")
def calculate_cfr():
    _ctx.result = calculate_change_failure_rate(_ctx.total_deployments, _ctx.failed_deployments)
    _ctx.no_data = _ctx.result is None


@then(parsers.parse("the Change Failure Rate is {expected:f}%"))
def assert_cfr_value(expected):
    assert _ctx.result is not None, "expected a numeric CFR, got no-data"
    assert _ctx.result == expected, f"expected CFR {expected}%, got {_ctx.result}%"


@then(parsers.parse('the Change Failure Rate calculation reports "{label}" instead of a divide-by-zero result'))
def assert_cfr_no_data(label):
    assert label == "no data"
    assert _ctx.no_data is True
    assert _ctx.result is None
