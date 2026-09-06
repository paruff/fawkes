"""Step definitions for the Tekton golden-path pipeline (#1804 Phase 1).

Every step here shells out to kubectl/gh against the live cluster - there is
no mocking. Tekton CRDs (Pipeline/PipelineRun/TaskRun/EventListener) are not
covered by the `kubernetes` Python client, so kubectl is used uniformly
rather than mixing the client for core resources and kubectl for Tekton ones.
"""

import json
import re
import subprocess
import time

import pytest
from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/golden-path-tekton.feature")

NAMESPACE = "fawkes"


def _kubectl(*args: str) -> str:
    result = subprocess.run(
        ["kubectl", "-n", NAMESPACE, *args],
        capture_output=True,
        text=True,
        timeout=30,
        check=True,
    )
    return result.stdout


def _kubectl_json(*args: str) -> dict:
    return json.loads(_kubectl(*args, "-o", "json"))


@pytest.fixture
def context():
    return {}


@given(parsers.parse('I have kubectl configured for the "{namespace}" namespace'))
def kubectl_configured(context, namespace):
    output = subprocess.run(
        ["kubectl", "get", "namespace", namespace],
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    assert output.returncode == 0, f"cluster unreachable or namespace missing: {output.stderr}"
    context["namespace"] = namespace


@when("I check the tekton-pipelines-controller and tekton-triggers-controller deployments")
def check_tekton_controllers(context):
    context["deployments"] = {
        name: _kubectl_json("get", "deployment", name)
        for name in ("tekton-pipelines-controller", "tekton-triggers-controller")
    }


@then("both deployments have all replicas available")
def assert_controllers_available(context):
    for name, deployment in context["deployments"].items():
        spec_replicas = deployment["spec"].get("replicas", 1)
        available = deployment.get("status", {}).get("availableReplicas", 0)
        assert available >= spec_replicas, f"{name}: {available}/{spec_replicas} replicas available"


@when(parsers.parse('I inspect the "{pipeline_name}" Pipeline definition'))
def inspect_pipeline(context, pipeline_name):
    context["pipeline"] = _kubectl_json("get", "pipeline", pipeline_name)


@then(parsers.parse('it defines tasks "{expected_tasks}" in that order'))
def assert_task_order(context, expected_tasks):
    expected = [t.strip() for t in expected_tasks.split(",")]
    actual = [t["name"] for t in context["pipeline"]["spec"]["tasks"]]
    assert actual == expected, f"expected task order {expected}, got {actual}"


@then(parsers.parse('the "{task_name}" task fails on CRITICAL or HIGH severity vulnerabilities'))
def assert_scan_severity(context, task_name):
    task = next(t for t in context["pipeline"]["spec"]["tasks"] if t["name"] == task_name)
    script = task["taskSpec"]["steps"][0]["script"]
    assert "--severity" in script and "CRITICAL,HIGH" in script, "scan step is missing the severity gate"
    assert "--exit-code 1" in script, "scan step does not fail the build on findings"


@then(parsers.parse('the "{task_name}" task has a step timeout configured'))
def assert_step_timeout(context, task_name):
    task = next(t for t in context["pipeline"]["spec"]["tasks"] if t["name"] == task_name)
    step = task["taskSpec"]["steps"][0]
    assert "timeout" in step, f"{task_name}'s step has no timeout - a stalled step can hang the whole PipelineRun"


@when(parsers.parse('I find the most recent "{task_name}" TaskRun for the "{pipeline_name}" pipeline'))
def find_most_recent_taskrun(context, task_name, pipeline_name):
    taskruns = _kubectl_json("get", "taskrun", "-l", f"tekton.dev/pipelineTask={task_name}")["items"]
    matching = [tr for tr in taskruns if tr["metadata"].get("labels", {}).get("tekton.dev/pipeline") == pipeline_name]
    assert matching, f"no {task_name} TaskRuns found for pipeline {pipeline_name}"
    matching.sort(key=lambda tr: tr["metadata"]["creationTimestamp"], reverse=True)
    context["taskrun"] = matching[0]


@then(parsers.parse('it completed with reason "{expected_reason}"'))
def assert_taskrun_reason(context, expected_reason):
    conditions = context["taskrun"]["status"]["conditions"]
    reason = conditions[0]["reason"]
    assert reason == expected_reason, f"expected reason {expected_reason}, got {reason}"


@when(parsers.parse('I check the "{listener_name}" EventListener\'s pod'))
def check_eventlistener_pod(context, listener_name):
    pods = _kubectl_json("get", "pod", "-l", f"eventlistener={listener_name}")["items"]
    assert pods, f"no pods found for EventListener {listener_name}"
    context["eventlistener_pod"] = pods[0]


@then("the pod is Running and ready")
def assert_pod_running_ready(context):
    pod = context["eventlistener_pod"]
    assert pod["status"]["phase"] == "Running", f"pod phase is {pod['status']['phase']}"
    statuses = pod["status"].get("containerStatuses", [])
    assert statuses and all(s["ready"] for s in statuses), "not all containers are ready"


@given(parsers.parse('a fresh PipelineRun is triggered for the "{pipeline_name}" pipeline'))
def trigger_pipelinerun(context, pipeline_name):
    output = subprocess.run(
        ["kubectl", "-n", NAMESPACE, "create", "-f", "-"],
        input=f"""
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: {pipeline_name}-bdd-
  namespace: {NAMESPACE}
spec:
  pipelineRef:
    name: {pipeline_name}
  taskRunTemplate:
    serviceAccountName: golden-path-pipeline-sa
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: golden-path-workspace
    - name: dockerconfig
      secret:
        secretName: ghcr-push-creds
        items:
          - key: .dockerconfigjson
            path: config.json
""",
        capture_output=True,
        text=True,
        timeout=15,
        check=True,
    )
    context["pipelinerun_name"] = output.stdout.split("/")[1].split()[0]


@when("I wait for the PipelineRun to finish", target_fixture="pipelinerun_result")
def wait_for_pipelinerun(context):
    name = context["pipelinerun_name"]
    deadline = time.monotonic() + 900
    while time.monotonic() < deadline:
        run = _kubectl_json("get", "pipelinerun", name)
        conditions = run.get("status", {}).get("conditions", [])
        if conditions and conditions[0]["status"] in ("True", "False"):
            taskruns = _kubectl_json("get", "taskrun", "-l", f"tekton.dev/pipelineRun={name}")["items"]
            context["taskruns_by_task"] = {tr["metadata"]["labels"]["tekton.dev/pipelineTask"]: tr for tr in taskruns}
            return
        time.sleep(15)
    raise TimeoutError(f"PipelineRun {name} did not finish within 15 minutes")


@then(parsers.parse('the "{task_list}" tasks succeed'))
def assert_tasks_succeed(context, task_list):
    # task_list is everything pytest-bdd's greedy {placeholder} captured between
    # the outer quotes, e.g. fetch-source", "lint-and-test", "build-and-push -
    # extract each quoted name individually rather than assuming a fixed
    # separator (Gherkin lists are sometimes written with an oxford "and").
    tasks = re.findall(r"([\w-]+)", task_list)
    for task_name in tasks:
        taskrun = context["taskruns_by_task"].get(task_name)
        assert taskrun is not None, f"{task_name} never ran"
        reason = taskrun["status"]["conditions"][0]["reason"]
        assert reason == "Succeeded", f"{task_name} did not succeed: {reason}"


@then(parsers.parse('the "{downstream}" task only runs if "{upstream}" succeeded'))
def assert_conditional_task(context, downstream, upstream):
    upstream_run = context["taskruns_by_task"].get(upstream)
    downstream_run = context["taskruns_by_task"].get(downstream)
    upstream_succeeded = upstream_run is not None and upstream_run["status"]["conditions"][0]["reason"] == "Succeeded"
    if upstream_succeeded:
        assert downstream_run is not None, f"{upstream} succeeded but {downstream} never ran"
    else:
        assert downstream_run is None, f"{upstream} did not succeed but {downstream} ran anyway"
