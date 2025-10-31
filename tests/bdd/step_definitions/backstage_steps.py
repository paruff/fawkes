from behave import given, when, then
import subprocess
import time
import logging
from kubernetes import client, config
from kubernetes.stream import stream

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def load_kube_clients():
    """Load kube config (prefers local kubeconfig then in-cluster) and return API clients."""
    try:
        config.load_kube_config()
        logger.info("Loaded kubeconfig from default location")
    except Exception:
        logger.info("Falling back to in-cluster kube config")
        config.load_incluster_config()

    core = client.CoreV1Api()
    apps = client.AppsV1Api()
    return core, apps


def run_helm(args, timeout=300):
    """Run a Helm command via subprocess and return (returncode, stdout, stderr).

    Args should be a list (e.g. ['upgrade','--install', ...])
    """
    cmd = ["helm"] + args
    logger.info("Running Helm: %s", " ".join(cmd))
    try:
        completed = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
        )
        logger.info("Helm succeeded: %s", completed.stdout)
        return completed.returncode, completed.stdout, completed.stderr
    except subprocess.CalledProcessError as e:
        logger.error("Helm failed (rc=%s): %s", e.returncode, e.stderr)
        raise


def find_pod_for_label(core_api, namespace, label_selector, timeout=120):
    """Find a running pod matching the label selector within timeout seconds."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        pods = core_api.list_namespaced_pod(namespace=namespace, label_selector=label_selector)
        for p in pods.items:
            if p.status.phase == 'Running':
                logger.info("Found running pod %s", p.metadata.name)
                return p.metadata.name
        time.sleep(2)
    raise RuntimeError(f"No running pod found for selector '{label_selector}' in {namespace}")


def exec_in_pod(core_api, namespace, pod_name, command, container=None, _timeout=30):
    """Execute a command in a pod and return stdout/stderr and exit code."""
    try:
        resp = stream(
            core_api.connect_get_namespaced_pod_exec,
            pod_name,
            namespace,
            command=command,
            stderr=True,
            stdin=False,
            stdout=True,
            tty=False,
            _preload_content=True,
            container=container,
        )
        return resp
    except Exception as e:
        logger.exception("Exec in pod failed: %s", e)
        raise


def wait_for_deployment_ready(apps_api, name, namespace, timeout=300, poll_interval=3):
    """Wait until deployment's available_replicas >= replicas (spec) or timeout."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            dep = apps_api.read_namespaced_deployment(name=name, namespace=namespace)
        except client.exceptions.ApiException as e:
            logger.debug("Deployment read failed: %s", e)
            time.sleep(poll_interval)
            continue

        spec_replicas = dep.spec.replicas or 1
        status_replicas = dep.status.available_replicas or 0
        logger.info("Deployment %s: available %s/%s", name, status_replicas, spec_replicas)
        if status_replicas >= spec_replicas:
            return True
        time.sleep(poll_interval)

    raise TimeoutError(f"Deployment {name} not ready within {timeout} seconds")


@given('a Backstage Helm chart at "{chart_path}" with release "{release}" in namespace "{namespace}"')
def step_given_backstage_chart(context, chart_path, release, namespace):
    context.chart_path = chart_path
    context.release = release
    context.namespace = namespace
    # prepare K8s clients lazily
    context.core_api = None
    context.apps_api = None


@when('I deploy Backstage with values file "{values_file}"')
def step_when_deploy_backstage(context, values_file):
    # Ensure kube clients ready (used later for checks)
    core, apps = load_kube_clients()
    context.core_api = core
    context.apps_api = apps

    args = [
        'upgrade',
        '--install',
        context.release,
        context.chart_path,
        '-n',
        context.namespace,
        '--create-namespace',
        '-f',
        values_file,
    ]
    # Run helm command
    run_helm(args)


@then('the deployment "{deployment_name}" becomes ready within {timeout:d} seconds')
def step_then_deployment_ready(context, deployment_name, timeout):
    if not getattr(context, 'apps_api', None):
        context.core_api, context.apps_api = load_kube_clients()
    wait_for_deployment_ready(context.apps_api, deployment_name, context.namespace, timeout=int(timeout))


@then('the service "{service_name}" responds to health check path "{path}" on port {port:d} within {timeout:d} seconds')
def step_then_service_health(context, service_name, path, port, timeout):
    # Ensure core_api available
    if not getattr(context, 'core_api', None):
        context.core_api, context.apps_api = load_kube_clients()

    # Use label selector to find a pod for the release. We try common selectors in order.
    # First try app=backstage, then release label
    selectors_to_try = [
        f"app={service_name}",
        f"app.kubernetes.io/name={service_name}",
        f"release={context.release}",
    ]

    pod_name = None
    last_exc = None
    for sel in selectors_to_try:
        try:
            pod_name = find_pod_for_label(context.core_api, context.namespace, sel, timeout=30)
            if pod_name:
                label_used = sel
                break
        except Exception as e:
            last_exc = e
            continue

    if not pod_name:
        raise RuntimeError(f"Could not locate a running pod for service {service_name}; last error: {last_exc}")

    # Build curl command to run inside pod. We assume the application listens on localhost inside the pod.
    curl_cmd = ['curl', '-s', '-S', '-o', '/dev/null', '-w', '%{http_code}', f'http://127.0.0.1:{port}{path}']

    deadline = time.time() + int(timeout)
    while time.time() < deadline:
        try:
            resp = exec_in_pod(context.core_api, context.namespace, pod_name, curl_cmd)
            # resp should be the HTTP status code string
            logger.info('Health check response from pod %s: %s', pod_name, resp)
            if resp.strip() and resp.strip().startswith('2'):
                return True
        except Exception as e:
            logger.debug('Health check exec failed: %s', e)
        time.sleep(2)

    raise TimeoutError(f"Health check for {service_name} at {path} did not return 2xx within {timeout}s")
