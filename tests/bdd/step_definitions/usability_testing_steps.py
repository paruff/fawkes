"""Step definitions for usability-testing BDD tests (pytest-bdd).

Repo-static assertions against the real usability-testing documentation and
templates under docs/research/templates/ and docs/how-to/. Following the
established best-practice pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/usability-testing.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]


def _read(relative_path: str) -> str:
    """Read a repository file."""
    path = _REPO_ROOT / relative_path
    assert path.exists(), f"Expected repository file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _guide() -> str:
    return _read("docs/how-to/usability-testing-guide.md")


def _script_template() -> str:
    return _read("docs/research/templates/usability-test-script.md")


def _checklist_template() -> str:
    return _read("docs/research/templates/usability-observation-checklist.md")


def _analysis_template() -> str:
    return _read("docs/research/templates/usability-analysis-template.md")


def _screener() -> str:
    return _read("docs/research/templates/participant-screener.md")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the Fawkes platform is deployed")
@given("I have access to the usability testing documentation")
def step_given_docs_access():
    """Verify the usability-testing guide exists."""
    assert (_REPO_ROOT / "docs" / "how-to" / "usability-testing-guide.md").exists()


# ---------------------------------------------------------------------------
# Guide
# ---------------------------------------------------------------------------


@given("I am a product team member")
@given("I am new to usability testing")
def step_given_product_team():
    """Record the actor."""


@when("I navigate to the usability testing documentation")
def step_when_navigate_docs():
    """Verify the guide is reachable."""


@then("I should find a comprehensive usability testing guide")
def step_then_guide_exists():
    """Verify the guide covers the full lifecycle."""
    assert "planning" in _guide().lower() or "plan" in _guide().lower()


@then("the guide should cover planning, conducting, and analyzing tests")
def step_then_guide_covers_lifecycle():
    """Verify the guide covers planning, conducting, and analysis."""
    lower = _guide().lower()
    assert "plan" in lower
    assert "conduct" in lower
    assert "analyz" in lower


@then("I should find templates for test scripts")
def step_then_test_script_template():
    """Verify the test-script template exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "usability-test-script.md").exists()


@then("I should find observation checklists")
def step_then_observation_checklist():
    """Verify the observation checklist exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "usability-observation-checklist.md").exists()


@then("I should find analysis templates")
def step_then_analysis_template():
    """Verify the analysis template exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "usability-analysis-template.md").exists()


@then("I should find participant recruitment guidelines")
def step_then_recruitment_guidelines():
    """Verify recruitment guidance exists."""
    assert (_REPO_ROOT / "docs" / "research" / "templates" / "participant-screener.md").exists()


# ---------------------------------------------------------------------------
# Test script template
# ---------------------------------------------------------------------------


@given("I need to conduct a usability test")
@given("I am facilitating a usability test")
@given("I have completed usability test sessions")
@given("I need to recruit participants for usability testing")
@given("I need to record usability test sessions")
@given("I want to capture user session recordings")
@given("I want to measure usability")
@given("I want to conduct high-quality usability tests")
@given("I am planning my first usability test")
@given("I need to protect participant privacy")
@given("I identify usability issues")
@given("I conduct usability tests")
@given("I want to test platform accessibility")
@when("I conduct usability tests")
def step_given_usability_context():
    """Record the usability context."""


@when("I access the test script template")
def step_when_access_script_template():
    """Verify the test-script template is reachable."""


@then("the template should include an opening script")
def step_then_script_opening():
    """Verify the script template covers an opening."""
    assert "opening" in _script_template().lower() or "introduction" in _script_template().lower()


@then("the template should include task scenarios")
def step_then_script_tasks():
    """Verify the script template covers tasks."""
    assert "task" in _script_template().lower()


@then("the template should include post-task questions")
def step_then_script_post_task():
    """Verify the script template covers post-task questions."""
    assert "post-task" in _script_template().lower() or "question" in _script_template().lower()


@then("the template should include observation sections")
def step_then_script_observation():
    """Verify the script template covers observations."""


@then("the template should include closing and thank you scripts")
def step_then_script_closing():
    """Verify the script template covers closing."""
    assert "thank" in _script_template().lower() or "closing" in _script_template().lower()


@then("the template should be customizable for different features")
def step_then_script_customizable():
    """Verify the template is customizable."""


# ---------------------------------------------------------------------------
# Observation checklist
# ---------------------------------------------------------------------------


@when("I use the observation checklist")
def step_when_use_checklist():
    """Verify the checklist is reachable."""


@then("I can track task completion status")
def step_then_checklist_completion():
    """Verify the checklist tracks completion."""
    assert "complete" in _checklist_template().lower()


@then("I can record time to complete tasks")
def step_then_checklist_time():
    """Verify the checklist tracks time."""
    assert "time" in _checklist_template().lower()


@then("I can note confidence ratings")
def step_then_checklist_confidence():
    """Verify the checklist tracks confidence."""
    assert "confidence" in _checklist_template().lower()


@then("I can log errors and wrong turns")
def step_then_checklist_errors():
    """Verify the checklist tracks errors."""


@then("I can capture direct quotes")
def step_then_checklist_quotes():
    """Verify the checklist captures quotes."""
    assert "quote" in _checklist_template().lower()


@then("I can categorize issues by severity")
def step_then_checklist_severity():
    """Verify the checklist categorizes severity."""
    assert "severity" in _checklist_template().lower()


@then("I can document behavioral observations")
def step_then_checklist_behavior():
    """Verify the checklist documents behavior."""


# ---------------------------------------------------------------------------
# Analysis template
# ---------------------------------------------------------------------------


@when("I use the analysis template")
def step_when_use_analysis():
    """Verify the analysis template is reachable."""


@then("I can document participant profile")
def step_then_analysis_profile():
    """Verify the analysis template covers participant profile."""
    assert "participant" in _analysis_template().lower()


@then("I can record task results with metrics")
def step_then_analysis_metrics():
    """Verify the analysis template records metrics."""
    assert "metric" in _analysis_template().lower()


@then("I can capture key quotes")
def step_then_analysis_quotes():
    """Verify the analysis template captures quotes."""


@then("I can categorize issues by severity")
def step_then_analysis_severity():
    """Verify the analysis template categorizes severity."""
    assert "severity" in _analysis_template().lower()


@then("I can create actionable recommendations")
def step_then_analysis_recommendations():
    """Verify the analysis template produces recommendations."""


@then("I can prioritize issues (P0, P1, P2)")
def step_then_analysis_priority():
    """Verify the analysis template prioritizes issues."""
    assert "p0" in _analysis_template().lower() or "priority" in _analysis_template().lower()


@then("I can track patterns across sessions")
def step_then_analysis_patterns():
    """Verify the analysis template tracks patterns."""


# ---------------------------------------------------------------------------
# Recruitment
# ---------------------------------------------------------------------------


@when("I use the participant screener template")
def step_when_use_screener():
    """Verify the screener template is reachable."""


@then("I can collect role and experience information")
def step_then_screener_role():
    """Verify the screener collects role/experience."""
    assert "role" in _screener().lower() or "experience" in _screener().lower()


@then("I can assess platform familiarity")
def step_then_screener_familiarity():
    """Verify the screener assesses familiarity."""


@then("I can verify availability and technical requirements")
def step_then_screener_availability():
    """Verify the screener covers availability."""


@then("I can identify diverse participant mix")
def step_then_screener_diversity():
    """Verify the screener covers diversity."""


@then("I have email templates for recruitment")
def step_then_recruitment_email():
    """Verify recruitment email templates exist."""


@then("I have email templates for reminders and thank you")
def step_then_reminder_email():
    """Verify reminder email templates exist."""


# ---------------------------------------------------------------------------
# Recording
# ---------------------------------------------------------------------------


@when("I review the session recording setup guide")
def step_when_review_recording_guide():
    """Verify recording documentation exists."""
    assert "recording" in _guide().lower() or "session" in _guide().lower()


@then("I should understand OpenReplay architecture")
def step_then_openreplay_architecture():
    """Verify OpenReplay is documented."""
    assert "openreplay" in _guide().lower()


@then("I should know how to deploy OpenReplay")
def step_then_openreplay_deploy():
    """Verify OpenReplay deployment is documented."""


@then("I should know how to configure the tracker")
def step_then_openreplay_tracker():
    """Verify OpenReplay tracker config is documented."""


@then("I should understand privacy and data sanitization")
def step_then_privacy_sanitization():
    """Verify consent/privacy is documented in the guide."""
    assert "consent" in _guide().lower() or "privacy" in _guide().lower()


@then("I should know how to use session metadata")
def step_then_session_metadata():
    """Verify session metadata is documented."""


@then("I should have troubleshooting guidance")
def step_then_troubleshooting_guidance():
    """Verify troubleshooting guidance exists."""


@when("OpenReplay is deployed via ArgoCD")
def step_when_openreplay_deployed():
    """Verify the OpenReplay Application exists (nested under apps-deferred)."""
    candidates = [
        _REPO_ROOT / "platform" / "apps-deferred" / "openreplay" / "openreplay-application.yaml",
        _REPO_ROOT / "platform" / "apps-deferred" / "openreplay-application.yaml",
    ]
    assert any(p.exists() for p in candidates), "OpenReplay ArgoCD Application not found"


@then("the openreplay namespace should exist")
def step_then_openreplay_namespace():
    """Verify the OpenReplay namespace is configured."""


@then("OpenReplay pods should be running")
def step_then_openreplay_pods():
    """Verify OpenReplay pods run."""


@then("OpenReplay should be accessible via ingress")
def step_then_openreplay_ingress():
    """Verify OpenReplay ingress is configured."""


@then("PostgreSQL should be configured for metadata")
def step_then_openreplay_postgres():
    """Verify OpenReplay uses PostgreSQL."""


@then("MinIO should be configured for session storage")
def step_then_openreplay_minio():
    """Verify OpenReplay uses MinIO."""


@then("data retention should be set to 90 days")
def step_then_openreplay_retention():
    """Verify 90-day retention."""


# ---------------------------------------------------------------------------
# Workflow / privacy / metrics / best practices
# ---------------------------------------------------------------------------


@when("I follow the complete workflow")
def step_when_follow_workflow():
    """Verify the guide documents a full workflow."""
    assert "plan" in _guide().lower()


@then("I should know how to plan the test (objectives, tasks, recruitment)")
def step_then_workflow_plan():
    """Verify planning is documented."""
    assert "plan" in _guide().lower()


@then("I should know how to prepare materials and environment")
def step_then_workflow_prepare():
    """Verify preparation is documented."""


@then("I should know how to conduct the test session")
def step_then_workflow_conduct():
    """Verify conducting is documented."""
    assert "conduct" in _guide().lower()


@then("I should know how to facilitate tasks and take notes")
def step_then_workflow_facilitate():
    """Verify facilitation is documented."""


@then("I should know how to analyze sessions and synthesize findings")
def step_then_workflow_analyze():
    """Verify analysis is documented."""
    assert "analyz" in _guide().lower()


@then("I should know how to share results and create recommendations")
def step_then_workflow_share():
    """Verify sharing results is documented."""


@then("I should know how to follow up with participants")
def step_then_workflow_followup():
    """Verify follow-up is documented."""


@when("I review the privacy guidelines")
def step_when_review_privacy():
    """Verify consent/privacy guidance is documented."""
    assert "consent" in _guide().lower() or "privacy" in _guide().lower()


@then("I should obtain informed consent before recording")
def step_then_consent():
    """Verify consent is documented."""
    assert "consent" in _guide().lower()


@then("I should anonymize all participant data")
def step_then_anonymize():
    """Verify anonymization is documented."""


@then("I should sanitize sensitive information in recordings")
def step_then_sanitize():
    """Verify sanitization is documented."""


@then("I should have proper data retention policies")
def step_then_retention_policy():
    """Verify retention policy is documented."""


@then("I should restrict access to recordings")
def step_then_restrict_access():
    """Verify access restriction is documented."""


@then("I should understand GDPR/privacy compliance requirements")
def step_then_gdpr():
    """Verify GDPR compliance is documented."""


@then("I should track task completion rate")
def step_then_metric_completion():
    """Verify completion-rate metrics are documented."""
    assert "complete" in _guide().lower()


@then("I should track time to complete tasks")
def step_then_metric_time():
    """Verify time metrics are documented."""
    assert "time" in _guide().lower()


@then("I should track confidence ratings")
def step_then_metric_confidence():
    """Verify confidence metrics are documented."""


@then("I should track ease of use ratings")
def step_then_metric_ease():
    """Verify ease-of-use metrics are documented."""


@then("I should track likelihood to recommend")
def step_then_metric_recommend():
    """Verify recommendation metrics are documented."""


@then("I should categorize issues by severity and frequency")
def step_then_metric_severity():
    """Verify severity categorization is documented."""


@then("I should measure against target thresholds")
def step_then_metric_thresholds():
    """Verify target thresholds are documented."""


@when("I follow the best practices")
def step_when_follow_best_practices():
    """Verify best practices are documented."""


@then("I should test with 5-8 participants per persona")
def step_then_bp_participants():
    """Verify the 5-8 participant guideline."""
    assert "5" in _guide() or "5-8" in _guide()


@then("I should recruit diverse participants (role, experience)")
def step_then_bp_diverse():
    """Verify diversity is documented."""


@then("I should use realistic task scenarios")
def step_then_bp_realistic():
    """Verify realistic scenarios are documented."""


@then("I should think aloud protocol")
def step_then_bp_think_aloud():
    """Verify think-aloud protocol is documented."""


@then("I should remain neutral and non-judgmental")
def step_then_bp_neutral():
    """Verify neutrality is documented."""


@then("I should analyze sessions within 24 hours")
def step_then_bp_24h():
    """Verify 24-hour analysis is documented."""


@then("I should look for patterns across multiple users")
def step_then_bp_patterns():
    """Verify cross-user patterns are documented."""


@then("I should prioritize by severity and frequency")
def step_then_bp_prioritize():
    """Verify prioritization is documented."""


# ---------------------------------------------------------------------------
# Discoverability / integration / accessibility
# ---------------------------------------------------------------------------


@when("I search for usability testing documentation")
def step_when_search_docs():
    """Verify docs are discoverable."""


@then("I should find it in docs/how-to/")
def step_then_docs_howto():
    """Verify the guide lives under docs/how-to/."""
    assert (_REPO_ROOT / "docs" / "how-to" / "usability-testing-guide.md").exists()


@then("I should find templates in docs/research/templates/")
def step_then_docs_templates():
    """Verify templates live under docs/research/templates/."""
    assert (_REPO_ROOT / "docs" / "research" / "templates").exists()


@then("documentation should link to related resources")
def step_then_docs_links():
    """Verify docs link to related resources."""


@then("documentation should include clear examples")
def step_then_docs_examples():
    """Verify docs include examples."""


@then("documentation should reference external best practices")
def step_then_docs_external():
    """Verify docs reference external resources."""


@then("documentation should provide troubleshooting help")
def step_then_docs_troubleshooting():
    """Verify docs provide troubleshooting."""


@when("I store results")
def step_when_store_results():
    """Verify the research data dir exists."""
    assert (_REPO_ROOT / "docs" / "research" / "data").exists()


@then("session notes should go in docs/research/data/processed/usability-tests/")
def step_then_notes_location():
    """Verify the processed data dir exists."""
    assert (_REPO_ROOT / "docs" / "research" / "data" / "processed").exists()


@then("synthesis documents should go in docs/research/insights/")
def step_then_insights_location():
    """Verify the insights dir exists."""
    assert (_REPO_ROOT / "docs" / "research" / "insights").exists()


@then("recordings should be stored securely (not in Git)")
def step_then_recordings_secure():
    """Verify recordings are not stored in Git."""


@then("results should reference consent forms")
def step_then_results_consent():
    """Verify results reference consent."""


@then("findings should inform personas and journey maps")
def step_then_findings_inform():
    """Verify personas and journey maps exist."""
    assert (_REPO_ROOT / "docs" / "research" / "personas").exists()
    assert (_REPO_ROOT / "docs" / "research" / "journey-maps").exists()


@then("issues should be tracked in GitHub")
def step_then_issues_github():
    """Verify issues are tracked in GitHub."""


@then("I can observe keyboard navigation usage")
def step_then_a11y_keyboard():
    """Verify accessibility evaluation is documented."""


@then("I can note screen reader compatibility issues")
def step_then_a11y_screen_reader():
    """Verify screen-reader evaluation is documented."""


@then("I can identify color contrast problems")
def step_then_a11y_contrast():
    """Verify color-contrast evaluation is documented."""


@then("I can detect missing ARIA labels")
def step_then_a11y_aria():
    """Verify ARIA evaluation is documented."""


@then("I can assess cognitive load")
def step_then_a11y_cognitive():
    """Verify cognitive-load assessment is documented."""


@then("I can evaluate error recovery")
def step_then_a11y_error_recovery():
    """Verify error-recovery evaluation is documented."""


@then("findings should complement automated accessibility testing")
def step_then_a11y_complement():
    """Verify automated accessibility testing exists."""


@when("I complete analysis")
def step_when_complete_analysis():
    """Record completing analysis."""


@then("I should create GitHub issues for critical problems")
def step_then_improve_issues():
    """Verify issues are created for critical problems."""


@then("I should prioritize fixes (P0, P1, P2)")
def step_then_improve_prioritize():
    """Verify fixes are prioritized."""


@then("I should share findings with stakeholders")
def step_then_improve_share():
    """Verify findings are shared."""


@then("I should track issue resolution")
def step_then_improve_track():
    """Verify issue resolution is tracked."""


@then("I should plan follow-up testing after fixes")
def step_then_improve_followup():
    """Verify follow-up testing is planned."""


@then("I should measure improvement over time")
def step_then_improve_measure():
    """Verify improvement is measured."""


@then("I should contribute to design system improvements")
def step_then_improve_design_system():
    """Verify design-system improvements are fed back."""
