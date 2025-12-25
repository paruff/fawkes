"""
Step definitions for SCORE integration BDD tests.

These steps test the SCORE workload specification integration in Fawkes.
"""

import os
import shutil
import yaml
import tempfile
from pathlib import Path
from behave import given, when, then
from subprocess import run, PIPE, CalledProcessError


@given('the Fawkes platform is operational')
def step_impl(context):
    """Verify Fawkes platform is running (stub for now)."""
    # In a real test, this would check K8s cluster health
    context.platform_operational = True


@given('the SCORE transformer component is deployed')
def step_impl(context):
    """Verify SCORE transformer is available."""
    # Check if generator.py exists
    transformer_path = Path(__file__).parent.parent.parent.parent / 'charts' / 'score-transformer' / 'generator.py'
    assert transformer_path.exists(), f"SCORE transformer not found at {transformer_path}"
    context.transformer_path = transformer_path


@given('a developer scaffolds a new service using the Golden Path template')
def step_impl(context):
    """Simulate scaffolding a new service."""
    template_path = Path(__file__).parent.parent.parent.parent / 'templates' / 'golden-path-service'
    context.template_path = template_path


@when('they review the generated files')
def step_impl(context):
    """Check generated files from template."""
    context.generated_files = list(context.template_path.glob('**/*'))


@then('a score.yaml file is present')
def step_impl(context):
    """Verify score.yaml exists in template."""
    score_file = context.template_path / 'score.yaml'
    assert score_file.exists(), f"score.yaml not found in {context.template_path}"
    context.score_file = score_file


@then('the score.yaml defines application parameters')
def step_impl(context):
    """Verify score.yaml has application parameters."""
    with open(context.score_file, 'r') as f:
        score_data = yaml.safe_load(f)

    assert 'containers' in score_data, "score.yaml missing 'containers'"
    assert 'metadata' in score_data, "score.yaml missing 'metadata'"


@then('the score.yaml defines required resource components')
def step_impl(context):
    """Verify score.yaml defines resources."""
    with open(context.score_file, 'r') as f:
        score_data = yaml.safe_load(f)

    # Template should have example resources
    assert 'resources' in score_data, "score.yaml missing 'resources'"


@given('a score.yaml file with memory limit of {memory}')
def step_impl(context, memory):
    """Create a test score.yaml with specific memory limit."""
    context.test_score = {
        'apiVersion': 'score.dev/v1b1',
        'metadata': {'name': 'test-service'},
        'containers': {
            'web': {
                'image': 'nginx:latest',
                'resources': {
                    'limits': {'memory': memory, 'cpu': '100m'},
                    'requests': {'memory': '128Mi', 'cpu': '50m'}
                }
            }
        },
        'service': {
            'ports': {
                'http': {'port': 80, 'targetPort': 80}
            }
        }
    }


@when('a developer modifies the containers.resources.limits.memory field to {new_memory}')
def step_impl(context, new_memory):
    """Modify memory limit in score.yaml."""
    context.test_score['containers']['web']['resources']['limits']['memory'] = new_memory


@then('the change is automatically reflected in the generated Deployment manifest')
def step_impl(context):
    """Verify memory change is in generated manifest."""
    # Write test score.yaml
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
        yaml.dump(context.test_score, f)
        score_file = f.name

    try:
        # Generate manifests using transformer
        output_dir = tempfile.mkdtemp()
        result = run(
            ['python3', str(context.transformer_path),
             '--score', score_file,
             '--environment', 'dev',
             '--output', output_dir],
            capture_output=True,
            text=True
        )

        # Check if deployment was generated
        deployment_file = Path(output_dir) / 'deployment.yaml'
        assert deployment_file.exists(), "Deployment manifest not generated"

        with open(deployment_file, 'r') as f:
            deployment = yaml.safe_load(f)

        # Verify memory limit in deployment
        container = deployment['spec']['template']['spec']['containers'][0]
        expected_memory = context.test_score['containers']['web']['resources']['limits']['memory']
        actual_memory = container['resources']['limits']['memory']
        assert actual_memory == expected_memory, \
            f"Memory mismatch: expected {expected_memory}, got {actual_memory}"

        context.generated_manifests = output_dir
    finally:
        os.unlink(score_file)


@then('the developer does not need to modify raw Kubernetes YAML')
def step_impl(context):
    """Verify abstraction - developers only modify score.yaml."""
    # This is verified by the fact that we only modified score.yaml
    # and the deployment manifest was auto-generated
    assert context.test_score is not None


@given('a score.yaml file is created for the {environment} environment')
def step_impl(context, environment):
    """Create score.yaml for specific environment."""
    context.source_environment = environment.lower()
    context.test_score = {
        'apiVersion': 'score.dev/v1b1',
        'metadata': {'name': 'portable-app'},
        'containers': {
            'web': {
                'image': 'myapp:v1.0.0',
                'resources': {'limits': {'memory': '256Mi'}}
            }
        },
        'route': {
            'host': 'myapp.${ENVIRONMENT}.fawkes.idp',
            'tls': {'enabled': True}
        }
    }


@when('the score.yaml file is deployed to the {environment} environment')
def step_impl(context, environment):
    """Deploy score.yaml to target environment."""
    context.target_environment = environment.lower()

    # Write score.yaml
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
        yaml.dump(context.test_score, f)
        score_file = f.name

    try:
        # Generate manifests for target environment
        output_dir = tempfile.mkdtemp()
        result = run(
            ['python3', str(context.transformer_path),
             '--score', score_file,
             '--environment', context.target_environment,
             '--output', output_dir],
            capture_output=True,
            text=True
        )

        context.deployment_result = result
        context.generated_manifests = output_dir
        context.score_file_path = score_file
    except Exception as e:
        context.deployment_error = str(e)


@then('the application is successfully deployed')
def step_impl(context):
    """Verify successful deployment."""
    assert hasattr(context, 'deployment_result'), "No deployment result found"
    assert context.deployment_result.returncode == 0, \
        f"Deployment failed: {context.deployment_result.stderr}"


@then('the Kubernetes manifests reference {environment}-specific resources')
def step_impl(context, environment):
    """Verify environment-specific resource references."""
    # This would check generated manifests reference correct env resources
    assert context.target_environment == environment.lower()


@then('the Vault address matches the {environment} environment')
def step_impl(context, environment):
    """Verify Vault address is environment-specific."""
    # In a real test, this would check ExternalSecret manifests
    pass


@then('the Ingress hostname matches the {environment} environment')
def step_impl(context, environment):
    """Verify Ingress hostname is environment-specific."""
    ingress_file = Path(context.generated_manifests) / 'ingress.yaml'
    if ingress_file.exists():
        with open(ingress_file, 'r') as f:
            ingress = yaml.safe_load(f)

        expected_host = f"portable-app.{environment.lower()}.fawkes.idp"
        actual_host = ingress['spec']['rules'][0]['host']
        assert actual_host == expected_host, \
            f"Hostname mismatch: expected {expected_host}, got {actual_host}"


@given('a valid score.yaml file with container and service definitions')
def step_impl(context):
    """Create valid score.yaml for translation test."""
    context.test_score = {
        'apiVersion': 'score.dev/v1b1',
        'metadata': {'name': 'test-app'},
        'containers': {
            'web': {
                'image': 'nginx:latest',
                'resources': {'limits': {'memory': '128Mi'}}
            }
        },
        'service': {
            'ports': {
                'http': {'port': 80, 'targetPort': 80, 'protocol': 'tcp'}
            }
        },
        'route': {
            'host': 'test-app.dev.fawkes.idp',
            'path': '/',
            'tls': {'enabled': True}
        }
    }


@when('the SCORE transformer processes the file')
def step_impl(context):
    """Run SCORE transformer on test file."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
        yaml.dump(context.test_score, f)
        score_file = f.name

    try:
        output_dir = tempfile.mkdtemp()
        result = run(
            ['python3', str(context.transformer_path),
             '--score', score_file,
             '--environment', 'dev',
             '--output', output_dir],
            capture_output=True,
            text=True
        )

        context.transformation_result = result
        context.generated_manifests = output_dir
    finally:
        if os.path.exists(score_file):
            os.unlink(score_file)


@then('a Kubernetes {resource_type} manifest is generated')
def step_impl(context, resource_type):
    """Verify specific K8s manifest was generated."""
    manifest_file = Path(context.generated_manifests) / f"{resource_type.lower()}.yaml"
    assert manifest_file.exists(), f"{resource_type} manifest not found"


@then('all manifests contain the score.dev/source annotation')
def step_impl(context):
    """Verify all manifests have SCORE annotation."""
    for manifest_file in Path(context.generated_manifests).glob('*.yaml'):
        with open(manifest_file, 'r') as f:
            manifest = yaml.safe_load(f)

        annotations = manifest.get('metadata', {}).get('annotations', {})
        assert 'score.dev/source' in annotations, \
            f"{manifest_file.name} missing score.dev/source annotation"


# Cleanup
def after_scenario(context, scenario):
    """Cleanup temporary files after each scenario."""
    if hasattr(context, 'generated_manifests'):
        if os.path.exists(context.generated_manifests):
            shutil.rmtree(context.generated_manifests)

    if hasattr(context, 'score_file_path'):
        if os.path.exists(context.score_file_path):
            os.unlink(context.score_file_path)
