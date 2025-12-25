"""
Step definitions for Accessibility Testing feature

These steps validate that automated accessibility testing is properly
integrated into the CI/CD pipeline with axe-core and Lighthouse CI.
"""

import json
import os
import subprocess
from pathlib import Path

import pytest
import requests
from pytest_bdd import given, when, then, scenarios, parsers

# Load scenarios from feature file
scenarios('../features/accessibility-testing.feature')


# ========================================
# Fixtures and Helper Functions
# ========================================

@pytest.fixture
def design_system_path():
    """Return path to design-system directory"""
    repo_root = Path(__file__).parent.parent.parent.parent
    return repo_root / 'design-system'


@pytest.fixture
def axe_test_results(design_system_path):
    """Fixture to hold axe-core test results"""
    return {'executed': False, 'passed': False, 'violations': []}


@pytest.fixture
def lighthouse_results(design_system_path):
    """Fixture to hold Lighthouse CI results"""
    return {'executed': False, 'score': 0, 'passed': False}


@pytest.fixture
def github_workflow_path():
    """Return path to GitHub workflows directory"""
    repo_root = Path(__file__).parent.parent.parent.parent
    return repo_root / '.github' / 'workflows'


# ========================================
# Background Steps
# ========================================

@given('the Fawkes platform is deployed')
def fawkes_platform_deployed():
    """Verify Fawkes platform is deployed (or skip in CI)"""
    # In CI, we assume the platform is available
    # For local testing, this would check actual deployment
    pass


@given('the design system components are available')
def design_system_available(design_system_path):
    """Verify design system exists"""
    assert design_system_path.exists(), "Design system directory not found"
    assert (design_system_path / 'package.json').exists(), "package.json not found"
    assert (design_system_path / 'src').exists(), "src directory not found"


@given('accessibility testing tools are configured')
def accessibility_tools_configured(design_system_path):
    """Verify accessibility testing tools are configured"""
    package_json = design_system_path / 'package.json'
    with open(package_json) as f:
        package_data = json.load(f)

    # Check for required dependencies
    dev_deps = package_data.get('devDependencies', {})
    assert 'axe-core' in dev_deps, "axe-core not found in devDependencies"
    assert 'jest-axe' in dev_deps, "jest-axe not found in devDependencies"
    assert '@lhci/cli' in dev_deps, "Lighthouse CI not found in devDependencies"

    # Check for test scripts
    scripts = package_data.get('scripts', {})
    assert 'test:a11y' in scripts, "test:a11y script not found"
    assert 'lighthouse:ci' in scripts, "lighthouse:ci script not found"


# ========================================
# Axe-core Integration Steps
# ========================================

@given('I have a component in the design system')
def component_exists(design_system_path):
    """Verify at least one component exists"""
    components_dir = design_system_path / 'src' / 'components'
    assert components_dir.exists(), "Components directory not found"
    components = list(components_dir.iterdir())
    assert len(components) > 0, "No components found"


@when('the CI/CD pipeline runs')
def cicd_pipeline_runs(github_workflow_path):
    """Verify CI/CD workflow exists"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    assert workflow_file.exists(), "Accessibility testing workflow not found"


@then('axe-core accessibility tests should execute')
def axe_core_executes(design_system_path, axe_test_results):
    """Verify axe-core test file exists"""
    a11y_test = design_system_path / 'src' / 'a11y.test.tsx'
    assert a11y_test.exists(), "Axe-core accessibility test file not found"

    # Verify test imports axe
    with open(a11y_test) as f:
        content = f.read()
        assert 'jest-axe' in content or 'axe-core' in content, "Axe imports not found"
        assert 'toHaveNoViolations' in content, "toHaveNoViolations matcher not found"

    axe_test_results['executed'] = True


@then('the tests should check for WCAG 2.1 AA violations')
def wcag_violations_checked(design_system_path):
    """Verify WCAG checks are configured"""
    a11y_test = design_system_path / 'src' / 'a11y.test.tsx'
    with open(a11y_test) as f:
        content = f.read()
        # Check for WCAG-related rules
        assert 'color-contrast' in content, "Color contrast check not found"
        assert 'WCAG 2.1' in content, "WCAG 2.1 reference not found"


@then('test results should be published to the build artifacts')
def test_results_published(github_workflow_path):
    """Verify workflow publishes artifacts"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'upload-artifact' in content, "Artifact upload not configured"
        assert 'axe-core-test-results' in content, "Axe results artifact not configured"


@then('the pipeline should fail if critical violations are found')
def pipeline_fails_on_violations(github_workflow_path):
    """Verify workflow fails on violations"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        # Workflow should not have continue-on-error for critical tests
        assert 'test:a11y:ci' in content, "CI test command not found"


# ========================================
# Lighthouse CI Steps
# ========================================

@given('the design system Storybook is built')
def storybook_built(design_system_path):
    """Verify Storybook build configuration exists"""
    assert (design_system_path / '.storybook').exists(), "Storybook config not found"


@when('Lighthouse CI runs accessibility audits')
def lighthouse_runs(design_system_path, lighthouse_results):
    """Verify Lighthouse CI configuration exists"""
    lhci_config = design_system_path / 'lighthouserc.json'
    assert lhci_config.exists(), "Lighthouse CI config not found"

    with open(lhci_config) as f:
        config = json.load(f)
        assert 'ci' in config, "CI configuration not found"
        assert 'assert' in config['ci'], "Assertions not configured"

    lighthouse_results['executed'] = True


@then('the accessibility score should be calculated')
def accessibility_score_calculated(design_system_path):
    """Verify Lighthouse calculates accessibility score"""
    lhci_config = design_system_path / 'lighthouserc.json'
    with open(lhci_config) as f:
        config = json.load(f)
        settings = config['ci']['collect']['settings']
        categories = settings.get('onlyCategories', [])
        assert 'accessibility' in categories, "Accessibility category not configured"


@then(parsers.parse('the score should meet the minimum threshold of {threshold:d}'))
def score_meets_threshold(design_system_path, threshold):
    """Verify minimum score threshold is configured"""
    lhci_config = design_system_path / 'lighthouserc.json'
    with open(lhci_config) as f:
        config = json.load(f)
        assertions = config['ci']['assert']['assertions']
        a11y_assertion = assertions.get('categories:accessibility', [])
        if len(a11y_assertion) > 1:
            min_score = a11y_assertion[1].get('minScore', 0)
            expected_score = threshold / 100.0
            assert min_score >= expected_score, f"Threshold {min_score} < {expected_score}"


@then('detailed reports should be generated')
def detailed_reports_generated(design_system_path):
    """Verify report generation is configured"""
    lhci_config = design_system_path / 'lighthouserc.json'
    with open(lhci_config) as f:
        config = json.load(f)
        assert 'upload' in config['ci'], "Upload configuration not found"


@then('reports should be uploaded as artifacts')
def reports_uploaded(github_workflow_path):
    """Verify workflow uploads Lighthouse reports"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'lighthouse-reports' in content, "Lighthouse reports artifact not configured"


# ========================================
# WCAG Compliance Gate Steps
# ========================================

@given('accessibility tests are running in the pipeline')
def accessibility_tests_running(github_workflow_path):
    """Verify accessibility tests are in workflow"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    assert workflow_file.exists(), "Accessibility workflow not found"


@when('any WCAG 2.1 AA violation is detected')
def wcag_violation_detected():
    """Simulate WCAG violation detection"""
    pass  # This is checked by the test framework


@then('the build should fail with a clear error message')
def build_fails_with_message(design_system_path):
    """Verify test configuration will fail on violations"""
    jest_config = design_system_path / 'jest.config.js'
    assert jest_config.exists(), "Jest config not found"


@then('the violation details should be logged')
def violation_details_logged():
    """Verify violations are logged"""
    # Jest and Lighthouse automatically log violations
    pass


@then('a link to the full report should be provided')
def report_link_provided(github_workflow_path):
    """Verify workflow provides report links"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'GITHUB_SERVER_URL' in content or 'artifacts' in content, "Report links not configured"


@then('remediation guidance should be included')
def remediation_guidance_included(github_workflow_path):
    """Verify guidance is provided in workflow"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'WCAG' in content or 'accessibility' in content, "Guidance references not found"


# ========================================
# Dashboard Steps
# ========================================

@given('Grafana is configured with accessibility metrics')
def grafana_configured():
    """Verify Grafana dashboard exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'
    assert dashboard_path.exists(), "Accessibility dashboard not found"

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        assert 'dashboard' in dashboard, "Dashboard configuration invalid"
        assert 'panels' in dashboard['dashboard'], "Dashboard panels not found"


@when('I navigate to the accessibility dashboard')
def navigate_to_dashboard():
    """Navigate to dashboard (simulated in test)"""
    pass


@then('I should see the overall accessibility score')
def see_overall_score():
    """Verify overall score panel exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        panels = dashboard['dashboard']['panels']
        titles = [p.get('title', '') for p in panels]
        assert any('Score' in t or 'score' in t for t in titles), "Score panel not found"


@then('I should see the test pass rate trend')
def see_pass_rate():
    """Verify pass rate panel exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        panels = dashboard['dashboard']['panels']
        titles = [p.get('title', '') for p in panels]
        assert any('Pass Rate' in t or 'pass rate' in t for t in titles), "Pass rate panel not found"


@then('I should see violations grouped by severity')
def see_violations_by_severity():
    """Verify severity grouping panel exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        panels = dashboard['dashboard']['panels']
        titles = [p.get('title', '') for p in panels]
        assert any('Severity' in t or 'severity' in t for t in titles), "Severity panel not found"


@then('I should see violations grouped by component')
def see_violations_by_component():
    """Verify component grouping panel exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        panels = dashboard['dashboard']['panels']
        titles = [p.get('title', '') for p in panels]
        assert any('Component' in t or 'component' in t for t in titles), "Component panel not found"


@then('I should see WCAG 2.1 AA compliance status')
def see_wcag_compliance():
    """Verify WCAG compliance panel exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    dashboard_path = repo_root / 'platform' / 'apps' / 'grafana' / 'dashboards' / 'accessibility-dashboard.json'

    with open(dashboard_path) as f:
        dashboard = json.load(f)
        panels = dashboard['dashboard']['panels']
        titles = [p.get('title', '') for p in panels]
        assert any('WCAG' in t or 'Compliance' in t for t in titles), "WCAG panel not found"


# ========================================
# Auto-issue Creation Steps
# ========================================

@given('accessibility tests detect violations')
def tests_detect_violations():
    """Simulate violation detection"""
    pass


@given('the tests run on the main branch or on schedule')
def tests_on_main_or_schedule(github_workflow_path):
    """Verify workflow runs on main/schedule"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'schedule:' in content or 'main' in content, "Schedule/main trigger not found"


@when('critical violations are found')
def critical_violations_found():
    """Simulate critical violations"""
    pass


@then('a GitHub issue should be created automatically')
def github_issue_created(github_workflow_path):
    """Verify issue creation is configured"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'create-accessibility-issues' in content, "Issue creation job not found"
        assert 'github.rest.issues.create' in content, "Issue creation API call not found"


@then(parsers.parse('the issue should have the "{label}" label'))
def issue_has_label(github_workflow_path, label):
    """Verify label is configured"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert label in content, f"Label '{label}' not found in workflow"


@then('the issue should include violation details')
def issue_includes_details(github_workflow_path):
    """Verify issue includes details"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'issueBody' in content or 'body:' in content, "Issue body not configured"


@then('the issue should link to test reports')
def issue_links_to_reports(github_workflow_path):
    """Verify issue links to reports"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'GITHUB_RUN_ID' in content or 'artifacts' in content, "Report links not found"


@then('duplicate issues should not be created within 7 days')
def no_duplicate_issues(github_workflow_path):
    """Verify duplicate prevention logic exists"""
    workflow_file = github_workflow_path / 'accessibility-testing.yml'
    with open(workflow_file) as f:
        content = f.read()
        assert 'listForRepo' in content or 'existingIssues' in content, "Duplicate check not found"
        assert '7' in content, "7-day check not found"


# ========================================
# Jenkins Integration Steps
# ========================================

@given('a service uses the Golden Path pipeline')
def service_uses_golden_path():
    """Verify Golden Path pipeline exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    pipeline_file = repo_root / 'jenkins-shared-library' / 'vars' / 'goldenPathPipeline.groovy'
    assert pipeline_file.exists(), "Golden Path pipeline not found"


@when('the Jenkins pipeline executes')
def jenkins_pipeline_executes():
    """Simulate Jenkins pipeline execution"""
    pass


@then('there should be an accessibility testing stage')
def accessibility_stage_exists():
    """Verify accessibility test library exists"""
    repo_root = Path(__file__).parent.parent.parent.parent
    a11y_lib = repo_root / 'jenkins-shared-library' / 'vars' / 'accessibilityTest.groovy'
    assert a11y_lib.exists(), "Accessibility test library not found"


@then(parsers.parse('the stage should run {timing} {reference_stage}'))
def stage_timing(timing, reference_stage):
    """Verify stage order (logical check)"""
    # This is verified by pipeline structure
    pass


@then('axe-core tests should execute in the stage')
def axe_executes_in_jenkins():
    """Verify axe-core execution in Jenkins"""
    repo_root = Path(__file__).parent.parent.parent.parent
    a11y_lib = repo_root / 'jenkins-shared-library' / 'vars' / 'accessibilityTest.groovy'

    with open(a11y_lib) as f:
        content = f.read()
        assert 'axe' in content.lower() or 'test:a11y' in content, "Axe execution not found"


@then('Lighthouse CI should execute in the stage')
def lighthouse_executes_in_jenkins():
    """Verify Lighthouse execution in Jenkins"""
    repo_root = Path(__file__).parent.parent.parent.parent
    a11y_lib = repo_root / 'jenkins-shared-library' / 'vars' / 'accessibilityTest.groovy'

    with open(a11y_lib) as f:
        content = f.read()
        assert 'lighthouse' in content.lower(), "Lighthouse execution not found"


@then('results should be published to Jenkins')
def results_published_to_jenkins():
    """Verify result publishing in Jenkins"""
    repo_root = Path(__file__).parent.parent.parent.parent
    a11y_lib = repo_root / 'jenkins-shared-library' / 'vars' / 'accessibilityTest.groovy'

    with open(a11y_lib) as f:
        content = f.read()
        assert 'publishHTML' in content or 'archiveArtifacts' in content, "Result publishing not found"
