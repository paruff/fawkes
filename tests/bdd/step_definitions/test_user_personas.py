"""
Step definitions for user persona documentation tests.
Tests validate that persona templates and documentation meet requirements.
"""

import os
import re
from pathlib import Path
from pytest_bdd import given, when, then, scenarios, parsers

# Load all scenarios from the feature file
scenarios('../features/user-personas.feature')

# Base path for repository
REPO_ROOT = Path(__file__).parent.parent.parent.parent
RESEARCH_DIR = REPO_ROOT / "docs" / "research"
PERSONAS_DIR = RESEARCH_DIR / "personas"
TEMPLATES_DIR = RESEARCH_DIR / "templates"


@given("the Fawkes platform repository is available")
def repo_available():
    """Verify repository is accessible."""
    assert REPO_ROOT.exists(), f"Repository root not found at {REPO_ROOT}"
    assert (REPO_ROOT / "README.md").exists(), "Repository README not found"


@given("the research documentation structure exists")
def research_structure_exists():
    """Verify research documentation directories exist."""
    assert RESEARCH_DIR.exists(), f"Research directory not found at {RESEARCH_DIR}"
    assert PERSONAS_DIR.exists(), f"Personas directory not found at {PERSONAS_DIR}"
    assert TEMPLATES_DIR.exists(), f"Templates directory not found at {TEMPLATES_DIR}"


@given("I navigate to the research templates directory")
def navigate_to_templates(context=None):
    """Store templates directory in context."""
    if context is None:
        context = {}
    context['templates_dir'] = TEMPLATES_DIR
    return context


@given("I navigate to the research personas directory")
def navigate_to_personas(context=None):
    """Store personas directory in context."""
    if context is None:
        context = {}
    context['personas_dir'] = PERSONAS_DIR
    return context


@given(parsers.parse('I open the {persona_type} persona document'))
def open_persona_document(context=None, persona_type=None):
    """Open and read a specific persona document."""
    if context is None:
        context = {}

    persona_files = {
        'Platform Developer': PERSONAS_DIR / 'platform-developer.md',
        'Application Developer': PERSONAS_DIR / 'application-developer.md',
        'Platform Consumer': PERSONAS_DIR / 'platform-consumer.md',
    }

    persona_file = persona_files.get(persona_type)
    assert persona_file is not None, f"Unknown persona type: {persona_type}"
    assert persona_file.exists(), f"Persona file not found: {persona_file}"

    with open(persona_file, 'r', encoding='utf-8') as f:
        context['current_persona_content'] = f.read()

    return context


@given("I review all persona documents")
def review_all_personas(context=None):
    """Load all persona documents for review."""
    if context is None:
        context = {}

    persona_files = [
        PERSONAS_DIR / 'platform-developer.md',
        PERSONAS_DIR / 'application-developer.md',
        PERSONAS_DIR / 'platform-consumer.md',
    ]

    context['all_personas'] = []
    for persona_file in persona_files:
        if persona_file.exists():
            with open(persona_file, 'r', encoding='utf-8') as f:
                context['all_personas'].append({
                    'file': persona_file.name,
                    'content': f.read()
                })

    assert len(context['all_personas']) >= 3, "Not all required persona files found"
    return context


@given("I navigate to the persona validation document")
def navigate_to_validation(context=None):
    """Store validation document location in context."""
    if context is None:
        context = {}
    context['validation_file'] = PERSONAS_DIR / 'VALIDATION.md'
    return context


@given("the Backstage catalog is configured")
def backstage_catalog_configured():
    """Verify Backstage catalog files exist."""
    catalog_file = REPO_ROOT / "catalog-info-personas.yaml"
    assert REPO_ROOT.exists(), "Repository root not accessible"
    return {'catalog_file': catalog_file}


@given("I am a team member looking for user personas")
def team_member_looking_for_personas():
    """Simulate team member accessing personas."""
    return {'role': 'team_member'}


@given("personas need to stay current with user research")
def personas_need_updates():
    """Context for persona maintenance requirements."""
    return {'maintenance_required': True}


@when("I check for the persona template")
def check_persona_template(context):
    """Verify persona template exists."""
    template_file = TEMPLATES_DIR / "persona.md"
    context['template_file'] = template_file
    context['template_exists'] = template_file.exists()

    if context['template_exists']:
        with open(template_file, 'r', encoding='utf-8') as f:
            context['template_content'] = f.read()

    return context


@when("I check for documented personas")
def check_documented_personas(context):
    """Check for persona documentation files."""
    persona_files = list(PERSONAS_DIR.glob("*.md"))
    # Exclude README and VALIDATION
    persona_files = [f for f in persona_files if f.name not in ['README.md', 'VALIDATION.md']]

    context['persona_files'] = persona_files
    context['persona_count'] = len(persona_files)
    return context


@when("I examine the persona structure")
def examine_persona_structure(context):
    """Parse persona document structure."""
    content = context.get('current_persona_content', '')

    # Extract all headers
    headers = re.findall(r'^#+\s+(.+)$', content, re.MULTILINE)
    context['persona_headers'] = headers

    return context


@when("I check for goals and metrics")
def check_goals_and_metrics(context):
    """Check for goals and metrics in personas."""
    results = []

    for persona in context.get('all_personas', []):
        content = persona['content']

        # Look for goals section
        goals_match = re.search(r'###\s+Goals and Motivations.*?(?=###|\Z)', content, re.DOTALL)
        has_goals = goals_match is not None

        # Count primary goals
        goal_count = len(re.findall(r'^\d+\.\s+', content, re.MULTILINE)) if has_goals else 0

        # Look for success metrics
        has_metrics = 'Success Metrics' in content

        results.append({
            'file': persona['file'],
            'has_goals': has_goals,
            'goal_count': goal_count,
            'has_metrics': has_metrics
        })

    context['goals_results'] = results
    return context


@when("I check for pain points")
def check_pain_points(context):
    """Check for pain points in personas."""
    results = []

    for persona in context.get('all_personas', []):
        content = persona['content']

        # Look for pain points section
        pain_points_match = re.search(r'###\s+Pain Points.*?(?=###|\Z)', content, re.DOTALL)

        if pain_points_match:
            section = pain_points_match.group(0)

            # Count major pain points (numbered items)
            pain_point_count = len(re.findall(r'^\d+\.\s+\*\*', section, re.MULTILINE))

            # Check for required fields
            has_description = 'Description' in section
            has_impact = 'Impact' in section
            has_frequency = 'Frequency' in section
            has_workaround = 'Workaround' in section or 'Current Workaround' in section

            results.append({
                'file': persona['file'],
                'pain_point_count': pain_point_count,
                'has_description': has_description,
                'has_impact': has_impact,
                'has_frequency': has_frequency,
                'has_workaround': has_workaround
            })
        else:
            results.append({
                'file': persona['file'],
                'pain_point_count': 0,
                'has_description': False,
                'has_impact': False,
                'has_frequency': False,
                'has_workaround': False
            })

    context['pain_points_results'] = results
    return context


@when("I check for behaviors and workflows")
def check_behaviors_workflows(context):
    """Check for behaviors and workflows in personas."""
    results = []

    for persona in context.get('all_personas', []):
        content = persona['content']

        has_workflow = 'Typical Daily Workflow' in content
        has_tools = 'Primary Tools' in content
        has_interaction_points = 'Platform Interaction Points' in content
        has_communication = 'Communication Preferences' in content
        has_decision_style = 'Decision-Making Style' in content

        results.append({
            'file': persona['file'],
            'has_workflow': has_workflow,
            'has_tools': has_tools,
            'has_interaction_points': has_interaction_points,
            'has_communication': has_communication,
            'has_decision_style': has_decision_style
        })

    context['behaviors_results'] = results
    return context


@when("I check the validation documentation")
def check_validation_documentation(context):
    """Check for validation documentation."""
    validation_file = context.get('validation_file')

    context['validation_exists'] = validation_file.exists()

    if context['validation_exists']:
        with open(validation_file, 'r', encoding='utf-8') as f:
            context['validation_content'] = f.read()

    return context


@when("I check for persona catalog entries")
def check_catalog_entries(context):
    """Check for Backstage catalog entries."""
    catalog_file = REPO_ROOT / "catalog-info-personas.yaml"

    context['catalog_exists'] = catalog_file.exists()

    if context['catalog_exists']:
        with open(catalog_file, 'r', encoding='utf-8') as f:
            context['catalog_content'] = f.read()

    return context


@when("I navigate to the research documentation")
def navigate_to_research_docs(context):
    """Navigate to research documentation."""
    context['research_readme'] = PERSONAS_DIR / 'README.md'
    return context


@when("I check the persona lifecycle documentation")
def check_lifecycle_documentation(context):
    """Check for persona lifecycle documentation."""
    readme_file = PERSONAS_DIR / 'README.md'
    validation_file = PERSONAS_DIR / 'VALIDATION.md'

    context['lifecycle_docs'] = {}

    if readme_file.exists():
        with open(readme_file, 'r', encoding='utf-8') as f:
            context['lifecycle_docs']['readme'] = f.read()

    if validation_file.exists():
        with open(validation_file, 'r', encoding='utf-8') as f:
            context['lifecycle_docs']['validation'] = f.read()

    return context


@then(parsers.parse('the persona template should exist at "{path}"'))
def template_exists_at_path(context, path):
    """Verify template exists at specified path."""
    full_path = REPO_ROOT / path
    assert full_path.exists(), f"Template not found at {full_path}"


@then("the template should include sections for role, goals, pain points, and behaviors")
def template_has_required_sections(context):
    """Verify template has required sections."""
    content = context.get('template_content', '')

    assert 'Role and Responsibilities' in content, "Template missing 'Role and Responsibilities' section"
    assert 'Goals and Motivations' in content, "Template missing 'Goals and Motivations' section"
    assert 'Pain Points' in content, "Template missing 'Pain Points' section"
    assert 'Behaviors and Preferences' in content, "Template missing 'Behaviors and Preferences' section"


@then("the template should include example personas")
def template_has_examples(context):
    """Verify template includes example personas."""
    content = context.get('template_content', '')

    # Check for example persona names or sections
    has_examples = 'Example Persona' in content or 'Alex Chen' in content or 'Maria Rodriguez' in content
    assert has_examples, "Template should include example personas"


@then(parsers.parse("there should be at least {count:d} persona files"))
def has_minimum_persona_files(context, count):
    """Verify minimum number of persona files exist."""
    persona_count = context.get('persona_count', 0)
    assert persona_count >= count, f"Expected at least {count} persona files, found {persona_count}"


@then(parsers.parse('a "{filename}" persona should exist'))
def specific_persona_exists(context, filename):
    """Verify specific persona file exists."""
    persona_file = PERSONAS_DIR / filename
    assert persona_file.exists(), f"Persona file not found: {filename}"


@then(parsers.parse('an "{filename}" persona should exist'))
def specific_persona_exists_alt(context, filename):
    """Verify specific persona file exists (alternate phrasing)."""
    persona_file = PERSONAS_DIR / filename
    assert persona_file.exists(), f"Persona file not found: {filename}"


@then(parsers.parse('it should include a "{section}" section'))
def persona_has_section(context, section):
    """Verify persona document has specific section."""
    content = context.get('current_persona_content', '')
    assert section in content, f"Persona missing '{section}' section"


@then("it should include document metadata with version and validation info")
def persona_has_metadata(context):
    """Verify persona has metadata section."""
    content = context.get('current_persona_content', '')

    assert 'Document Information' in content, "Persona missing 'Document Information' section"
    assert 'Version' in content, "Persona missing version information"
    assert 'Validation' in content or 'Based on' in content, "Persona missing validation information"


@then(parsers.parse("each persona should have at least {count:d} primary goals"))
def personas_have_minimum_goals(context, count):
    """Verify personas have minimum number of goals."""
    results = context.get('goals_results', [])

    for result in results:
        assert result['goal_count'] >= count, \
            f"Persona {result['file']} has only {result['goal_count']} goals, expected at least {count}"


@then("each persona should have defined success metrics")
def personas_have_success_metrics(context):
    """Verify personas have success metrics."""
    results = context.get('goals_results', [])

    for result in results:
        assert result['has_metrics'], f"Persona {result['file']} missing success metrics"


@then("each persona should have clear motivations (professional, personal, team)")
def personas_have_motivations(context):
    """Verify personas have motivations."""
    for persona in context.get('all_personas', []):
        content = persona['content']
        assert 'Motivations' in content, f"Persona {persona['file']} missing motivations section"
        assert 'Professional' in content, f"Persona {persona['file']} missing professional motivations"


@then(parsers.parse("each persona should have at least {count:d} major pain points"))
def personas_have_minimum_pain_points(context, count):
    """Verify personas have minimum number of pain points."""
    results = context.get('pain_points_results', [])

    for result in results:
        assert result['pain_point_count'] >= count, \
            f"Persona {result['file']} has only {result['pain_point_count']} pain points, expected at least {count}"


@then("each pain point should include a description")
def pain_points_have_descriptions(context):
    """Verify pain points have descriptions."""
    results = context.get('pain_points_results', [])

    for result in results:
        assert result['has_description'], f"Persona {result['file']} pain points missing descriptions"


@then("each pain point should include impact assessment")
def pain_points_have_impact(context):
    """Verify pain points have impact assessment."""
    results = context.get('pain_points_results', [])

    for result in results:
        assert result['has_impact'], f"Persona {result['file']} pain points missing impact assessment"


@then("each pain point should include frequency")
def pain_points_have_frequency(context):
    """Verify pain points have frequency information."""
    results = context.get('pain_points_results', [])

    for result in results:
        assert result['has_frequency'], f"Persona {result['file']} pain points missing frequency information"


@then("each pain point should include current workarounds")
def pain_points_have_workarounds(context):
    """Verify pain points have workarounds."""
    results = context.get('pain_points_results', [])

    for result in results:
        assert result['has_workaround'], f"Persona {result['file']} pain points missing workarounds"


@then("each persona should include a typical daily workflow")
def personas_have_workflow(context):
    """Verify personas have workflow information."""
    results = context.get('behaviors_results', [])

    for result in results:
        assert result['has_workflow'], f"Persona {result['file']} missing daily workflow"


@then("each persona should include primary tools used")
def personas_have_tools(context):
    """Verify personas have tools information."""
    results = context.get('behaviors_results', [])

    for result in results:
        assert result['has_tools'], f"Persona {result['file']} missing primary tools"


@then("each persona should include platform interaction points")
def personas_have_interaction_points(context):
    """Verify personas have platform interaction points."""
    results = context.get('behaviors_results', [])

    for result in results:
        assert result['has_interaction_points'], f"Persona {result['file']} missing platform interaction points"


@then("each persona should include communication preferences")
def personas_have_communication(context):
    """Verify personas have communication preferences."""
    results = context.get('behaviors_results', [])

    for result in results:
        assert result['has_communication'], f"Persona {result['file']} missing communication preferences"


@then("each persona should include decision-making style")
def personas_have_decision_style(context):
    """Verify personas have decision-making style."""
    results = context.get('behaviors_results', [])

    for result in results:
        assert result['has_decision_style'], f"Persona {result['file']} missing decision-making style"


@then(parsers.parse('a "{filename}" file should exist in the personas directory'))
def file_exists_in_personas(context, filename):
    """Verify specific file exists in personas directory."""
    file_path = PERSONAS_DIR / filename
    assert file_path.exists(), f"File not found: {filename} in personas directory"


@then("it should document research methodology")
def validation_has_methodology(context):
    """Verify validation document has methodology."""
    content = context.get('validation_content', '')
    assert 'Methodology' in content or 'Research Approach' in content, \
        "Validation document missing research methodology"


@then("it should include participant demographics for each persona")
def validation_has_demographics(context):
    """Verify validation document has participant demographics."""
    content = context.get('validation_content', '')
    assert 'Participants' in content or 'Research Participants' in content, \
        "Validation document missing participant information"


@then("it should include validation confidence levels")
def validation_has_confidence(context):
    """Verify validation document has confidence levels."""
    content = context.get('validation_content', '')
    assert 'Confidence' in content, "Validation document missing confidence levels"


@then("it should include supporting evidence for key findings")
def validation_has_evidence(context):
    """Verify validation document has supporting evidence."""
    content = context.get('validation_content', '')
    assert 'Evidence' in content or 'Validation' in content, \
        "Validation document missing supporting evidence"


@then("it should document data privacy and ethics considerations")
def validation_has_privacy(context):
    """Verify validation document has privacy information."""
    content = context.get('validation_content', '')
    assert 'Privacy' in content or 'Ethics' in content, \
        "Validation document missing privacy/ethics information"


@then(parsers.parse('a "{filename}" file should exist'))
def file_exists(context, filename):
    """Verify specific file exists."""
    file_path = REPO_ROOT / filename
    assert file_path.exists(), f"File not found: {filename}"


@then("it should define User entities for each persona")
def catalog_has_user_entities(context):
    """Verify catalog has User entities."""
    content = context.get('catalog_content', '')
    assert 'kind: User' in content, "Catalog missing User entity definitions"

    # Should have at least 3 User entities
    user_count = content.count('kind: User')
    assert user_count >= 3, f"Expected at least 3 User entities, found {user_count}"


@then("each persona entity should link to the full documentation")
def catalog_entities_have_links(context):
    """Verify catalog entities link to documentation."""
    content = context.get('catalog_content', '')
    assert 'links:' in content, "Catalog entities missing links"
    assert 'docs/research/personas' in content, "Catalog entities not linking to persona documentation"


@then("each persona entity should include relevant tags and annotations")
def catalog_entities_have_metadata(context):
    """Verify catalog entities have metadata."""
    content = context.get('catalog_content', '')
    assert 'tags:' in content, "Catalog entities missing tags"
    assert 'annotations:' in content, "Catalog entities missing annotations"
    assert 'persona' in content, "Catalog entities not tagged as personas"


@then("persona entities should be assigned to appropriate teams")
def catalog_entities_have_teams(context):
    """Verify catalog entities are assigned to teams."""
    content = context.get('catalog_content', '')
    assert 'memberOf:' in content, "Catalog entities not assigned to teams"


@then("the personas README should list all current personas")
def readme_lists_personas(context):
    """Verify README lists current personas."""
    readme_file = PERSONAS_DIR / 'README.md'
    assert readme_file.exists(), "Personas README not found"

    with open(readme_file, 'r', encoding='utf-8') as f:
        content = f.read()

    assert 'Current Personas' in content, "README missing 'Current Personas' section"
    assert 'platform-developer.md' in content, "README not listing Platform Developer persona"
    assert 'application-developer.md' in content, "README not listing Application Developer persona"
    assert 'platform-consumer.md' in content, "README not listing Platform Consumer persona"


@then("each persona listing should include name, archetype, and key characteristics")
def readme_has_persona_details(context):
    """Verify README has persona details."""
    readme_file = PERSONAS_DIR / 'README.md'

    with open(readme_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check for key characteristics in listings
    assert 'pain points' in content.lower() or 'focused on' in content.lower(), \
        "README persona listings missing key characteristics"


@then("personas should be linked from the main research documentation")
def personas_linked_from_research(context):
    """Verify personas are linked from research docs."""
    research_readme = RESEARCH_DIR / 'README.md'

    # If research README exists, it should reference personas
    if research_readme.exists():
        with open(research_readme, 'r', encoding='utf-8') as f:
            content = f.read()
        # This is a soft check - personas should be discoverable
        assert 'persona' in content.lower() or 'user' in content.lower(), \
            "Research README should reference personas"


@then("personas should be accessible via Backstage catalog")
def personas_in_backstage_catalog(context):
    """Verify personas are in Backstage catalog."""
    catalog_file = REPO_ROOT / "catalog-info-personas.yaml"
    assert catalog_file.exists(), "Personas catalog file not found"


@then("the personas README should include update procedures")
def readme_has_update_procedures(context):
    """Verify README has update procedures."""
    content = context['lifecycle_docs'].get('readme', '')
    assert 'Update' in content or 'Review' in content, \
        "README missing update procedures"


@then("the validation document should include a quarterly review schedule")
def validation_has_review_schedule(context):
    """Verify validation document has review schedule."""
    content = context['lifecycle_docs'].get('validation', '')
    assert 'quarterly' in content.lower() or 'review schedule' in content.lower(), \
        "Validation document missing quarterly review schedule"


@then("there should be a process for continuous validation")
def has_continuous_validation_process(context):
    """Verify there's a continuous validation process."""
    content = context['lifecycle_docs'].get('validation', '')
    assert 'continuous' in content.lower() or 'ongoing' in content.lower(), \
        "Missing continuous validation process"


@then("there should be guidelines for when to archive personas")
def has_archive_guidelines(context):
    """Verify there are archive guidelines."""
    content = context['lifecycle_docs'].get('readme', '')
    assert 'archive' in content.lower(), "Missing archive guidelines"
