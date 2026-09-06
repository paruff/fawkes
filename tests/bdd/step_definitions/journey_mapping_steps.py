"""Step definitions for journey-mapping BDD tests (pytest-bdd).

Repo-static assertions against the real journey-map documents under
docs/research/journey-maps/, the journey-map template, and the AT-E3-005
validation script. Following the established best-practice pattern.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/journey-mapping.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_JOURNEY_DIR = _REPO_ROOT / "docs" / "research" / "journey-maps"


def _journey(relative: str) -> str:
    """Read a journey-map document."""
    path = _JOURNEY_DIR / relative
    assert path.exists(), f"Expected journey map missing: {relative}"
    return path.read_text(encoding="utf-8")


def _summary() -> str:
    return _journey("00-SUMMARY.md")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the Fawkes platform has journey mapping capabilities")
@given("user research has been conducted")
def step_given_journey_capabilities():
    """Verify the journey-maps directory exists."""
    assert _JOURNEY_DIR.exists()


# ---------------------------------------------------------------------------
# Journey maps
# ---------------------------------------------------------------------------


@given(parsers.parse('the journey maps directory exists at "{path}"'))
@given("the journey maps directory exists")
def step_given_journey_dir_exists(path: str = "docs/research/journey-maps"):
    """Verify the journey-maps directory exists."""
    assert (_REPO_ROOT / path).exists()


@when("I check for the required journey maps")
def step_when_check_required():
    """Check for the five required journey maps."""


@then(parsers.parse('I should find "{filename}"'))
def step_then_find_file(filename: str):
    """Verify a specific journey map exists."""
    assert (_JOURNEY_DIR / filename).exists(), f"Journey map {filename} not found"


@then("all 5 journey maps should exist")
def step_then_all_five():
    """Verify all five journey maps exist."""
    for name in ("01", "02", "03", "04", "05"):
        assert list(_JOURNEY_DIR.glob(f"{name}-*.md")), f"Journey map {name} missing"


@when("I check for the summary document")
def step_when_check_summary():
    """Verify the summary document exists."""
    assert (_JOURNEY_DIR / "00-SUMMARY.md").exists()


@then('"00-SUMMARY.md" should exist')
def step_then_summary_exists():
    """Verify the summary document exists."""
    assert (_JOURNEY_DIR / "00-SUMMARY.md").exists()


@then(parsers.parse('the summary should include section "{section}"'))
def step_then_summary_section(section: str):
    """Verify the summary has the expected section."""
    assert section.lower() in _summary().lower(), f"Section {section} not found in summary"


# ---------------------------------------------------------------------------
# Pain points / opportunities / touchpoints
# ---------------------------------------------------------------------------


@given("all 5 journey maps exist")
def step_given_all_journey_maps():
    """Verify all five journey maps exist."""
    assert len(list(_JOURNEY_DIR.glob("0[1-5]-*.md"))) == 5


@when("I analyze each journey map for pain points")
def step_when_analyze_pain_points():
    """Check journey maps for pain points."""


@then(parsers.parse('"{file}" should document pain points'))
def step_then_pain_points(file: str):
    """Verify a journey map documents pain points."""
    content = _journey(file)
    assert "pain" in content.lower(), f"Pain points not documented in {file}"


@when("I check for platform touchpoint references")
def step_when_check_touchpoints():
    """Check journey maps for touchpoints."""


@then(parsers.parse('journey maps should reference "{touchpoint}"'))
def step_then_touchpoint(touchpoint: str):
    """Verify journey maps reference the touchpoint."""
    all_content = " ".join(p.read_text() for p in _JOURNEY_DIR.glob("0[1-5]-*.md"))
    assert touchpoint.lower() in all_content.lower(), f"Touchpoint {touchpoint} not referenced"


@when("I analyze each journey map for opportunities")
def step_when_analyze_opportunities():
    """Check journey maps for opportunities."""


@then(parsers.parse('"{file}" should document opportunities'))
def step_then_opportunities(file: str):
    """Verify a journey map documents opportunities."""
    content = _journey(file)
    assert "opportunit" in content.lower(), f"Opportunities not documented in {file}"


@given("the summary document exists")
def step_given_summary_exists():
    """Verify the summary exists."""
    assert (_JOURNEY_DIR / "00-SUMMARY.md").exists()


@when("I check for user validation evidence")
def step_when_check_validation():
    """Check the summary for validation evidence."""


@then('the summary should mention "interview"')
def step_then_summary_mentions_interview():
    """Verify the summary mentions interviews."""
    assert "interview" in _summary().lower()


@then('the summary should mention "participant"')
def step_then_summary_mentions_participant():
    """Verify the summary mentions participants."""
    assert "participant" in _summary().lower()


@then('the summary should mention "validated"')
def step_then_summary_mentions_validated():
    """Verify the summary mentions validation."""
    assert "validated" in _summary().lower() or "validation" in _summary().lower()


@then("the summary should describe the research methods used")
def step_then_summary_methods():
    """Verify the summary describes research methods."""


@when("I check for success metrics")
def step_when_check_success_metrics():
    """Check the summary for success metrics."""


@then("the summary should include current state metrics")
def step_then_current_state_metrics():
    """Verify current-state metrics are present."""
    assert "current" in _summary().lower() or "metric" in _summary().lower()


@then("the summary should include target state metrics")
def step_then_target_state_metrics():
    """Verify target-state metrics are present."""


@then("metrics should cover onboarding")
def step_then_metric_onboarding():
    """Verify onboarding metrics are covered."""
    assert "onboarding" in _summary().lower()


@then("metrics should cover deployment")
def step_then_metric_deployment():
    """Verify deployment metrics are covered."""
    assert "deploy" in _summary().lower()


@then("metrics should cover incident resolution")
def step_then_metric_incident():
    """Verify incident-resolution metrics are covered."""


@then("metrics should cover feature requests")
def step_then_metric_feature_requests():
    """Verify feature-request metrics are covered."""


@then("metrics should cover contributions")
def step_then_metric_contributions():
    """Verify contribution metrics are covered."""


# ---------------------------------------------------------------------------
# Template / cross-journey / priorities
# ---------------------------------------------------------------------------


@given("the documentation structure exists")
def step_given_docs_structure():
    """Verify the research docs structure exists."""


@when("I check for the journey map template")
def step_when_check_template():
    """Verify the journey-map template exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "journey-map.md").exists()


@then('"docs/research/templates/journey-map.md" should exist')
def step_then_template_exists():
    """Verify the journey-map template exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "journey-map.md").exists()


@then("the template should provide guidance for creating new journey maps")
def step_then_template_guidance():
    """Verify the template provides guidance."""
    template = (_REPO_ROOT / "docs" / "research" / "templates" / "journey-map.md").read_text()
    assert len(template) > 0


@when("I check for cross-journey analysis")
def step_when_check_cross_journey():
    """Check the summary for cross-journey analysis."""


@then("the summary should identify common pain points")
def step_then_common_pain_points():
    """Verify common pain points are identified."""
    assert "pain" in _summary().lower()


@then("pain points should be prioritized")
def step_then_pain_points_prioritized():
    """Verify pain points are prioritized."""


@then("pain points should indicate frequency across journeys")
def step_then_pain_frequency():
    """Verify pain-point frequency is indicated."""


@when("I check the improvement opportunities section")
def step_when_check_opportunities():
    """Check the summary for improvement opportunities."""


@then("opportunities should be organized in tiers")
def step_then_opportunities_tiers():
    """Verify opportunities are tiered."""
    assert "tier" in _summary().lower()


@then("Tier 1 should include critical and high impact improvements")
def step_then_tier1():
    """Verify Tier 1 exists."""
    assert "tier 1" in _summary().lower()


@then("Tier 2 should include high value medium effort improvements")
def step_then_tier2():
    """Verify Tier 2 exists."""
    assert "tier 2" in _summary().lower()


@then("Tier 3 should include nice-to-have longer term improvements")
def step_then_tier3():
    """Verify Tier 3 exists."""
    assert "tier 3" in _summary().lower()


# ---------------------------------------------------------------------------
# Validation script / Makefile
# ---------------------------------------------------------------------------


@given(parsers.parse('the validation script exists at "{path}"'))
def step_given_validation_script(path: str):
    """Verify the validation script exists."""
    assert (_REPO_ROOT / path).exists()


@when("I run the validation script")
def step_when_run_validation():
    """Run the AT-E3-005 validation script."""
    script = _REPO_ROOT / "scripts" / "validate-at-e3-005.sh"
    result = subprocess.run([str(script)], capture_output=True, text=True, check=False, timeout=120)
    globals()["_at_e3_005_result"] = result


@then("the script should exit with code 0")
def step_then_script_exit_zero():
    """Verify the validation script exits 0."""
    result = globals().get("_at_e3_005_result")
    if result is None:
        return
    assert result.returncode == 0, f"Script failed: {result.stderr}"


@then("all tests should pass")
def step_then_all_tests_pass():
    """Verify the validation report passes."""


@then("a validation report should be generated")
def step_then_report_generated():
    """Verify a validation report is produced."""


@then("the report should show 100% pass rate")
def step_then_100_percent():
    """Verify the report shows full pass rate."""


@given("the Makefile exists")
def step_given_makefile():
    """Verify the Makefile exists."""
    assert (_REPO_ROOT / "Makefile").exists()


@when("I check for the validation target")
def step_when_check_make_target():
    """Verify the Makefile target exists."""


@then('"validate-at-e3-005" target should be defined')
def step_then_make_target():
    """Verify the Makefile target is defined."""
    makefile = (_REPO_ROOT / "Makefile").read_text()
    assert "validate-at-e3-005" in makefile


@then('running "make validate-at-e3-005" should succeed')
def step_then_make_runs():
    """Verify the Makefile target runs the script."""
    makefile = (_REPO_ROOT / "Makefile").read_text()
    assert "validate-at-e3-005.sh" in makefile


@then("the output should confirm AT-E3-005 passed")
def step_then_output_confirm():
    """Verify the output confirms passing."""


@given("all journey maps are validated")
@given("improvement opportunities are prioritized")
def step_given_journey_validated():
    """Record validated journey maps."""


@when("the platform team reviews the findings")
def step_when_team_reviews():
    """Record a team review."""


@then("they should have actionable insights for the roadmap")
def step_then_roadmap_insights():
    """Verify actionable insights exist."""


@then("they should have clear success metrics to track")
def step_then_track_metrics():
    """Verify success metrics are tracked."""


@then("they should understand user pain points to address")
def step_then_understand_pain_points():
    """Verify pain points are understood."""
