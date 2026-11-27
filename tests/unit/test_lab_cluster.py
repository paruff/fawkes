"""The mmm4 lab: wave 1 only, same templates as the real cluster, its own GitOps branch."""

from pathlib import Path

import yaml
from test_applicationset_generator_paths import REPO_ROOT, generator_paths, load_applicationsets

WAVE_1 = {
    "ingress-nginx",
    "cert-manager",
    "argo-rollouts",
    "tekton",
    "prometheus-stack",
    "python-fawkes-path",
    "python-fawkes-path-analysis-template",
}


def appsets(directory: str) -> dict[str, dict]:
    return {doc["metadata"]["name"]: doc["spec"] for _, doc in load_applicationsets(REPO_ROOT, directory)}


def lab_files() -> list[Path]:
    return [
        REPO_ROOT / path for spec in appsets("platform/lab").values() for path in generator_paths(spec["generators"])
    ]


def read(relative: str) -> dict:
    return yaml.safe_load((REPO_ROOT / relative).read_text())


def test_lab_deploys_exactly_wave_1() -> None:
    assert sorted(read(str(f))["metadata"]["name"] for f in lab_files()) == sorted(WAVE_1)


def test_lab_templates_match_the_real_cluster() -> None:
    """A lab that renders Applications differently proves nothing about the real one."""
    real, lab = appsets("platform/bootstrap"), appsets("platform/lab")
    for lab_name, real_name in (("lab-platform", "platform-applications"), ("lab-path", "path-based-applications")):
        expected = dict(real[real_name]["template"]["spec"])
        assert lab[lab_name]["template"]["spec"] == expected, lab_name
        assert lab[lab_name]["syncPolicy"] == {"applicationsSync": "create-update"}


def test_sample_app_follows_the_lab_branch() -> None:
    source = read("platform/lab/python-fawkes-path-application.yaml")["spec"]["source"]
    assert source["targetRevision"] == "lab"


def test_root_application_never_prunes_the_applicationsets() -> None:
    root = read("platform/lab/root-application.yaml")["spec"]
    assert root["source"]["path"] == "platform/lab"
    assert root["syncPolicy"]["automated"]["prune"] is False


def test_pipeline_can_promote_to_another_branch_without_counting_it_as_production() -> None:
    documents = yaml.safe_load_all((REPO_ROOT / "platform/apps/tekton/golden-path-pipeline.yaml").read_text())
    pipeline = next(d for d in documents if d and d["kind"] == "Pipeline")
    params = {p["name"]: p for p in pipeline["spec"]["params"]}
    assert params["gitops-branch"]["default"] == "main"
    script = next(t for t in pipeline["spec"]["tasks"] if t["name"] == "gitops-promote")["taskSpec"]["steps"][0][
        "script"
    ]
    assert '--base "$(params.gitops-branch)"' in script
    assert '--branch "$(params.gitops-branch)"' in script
    assert script.index('!= "main"') < script.index("DEPLOY_PAYLOAD=")


def test_lab_ingress_differs_only_where_arm_needs_it() -> None:
    """defaultbackend-amd64 cannot run on the ARM node and blocks the admission webhook setup."""
    real = read("platform/apps/ingress-nginx/ingress-nginx-application.yaml")
    lab = read("platform/lab/ingress-nginx-application.yaml")
    assert lab["spec"]["source"]["helm"]["valuesObject"]["defaultBackend"] == {"enabled": False}
    for doc in (real, lab):
        del doc["spec"]["source"]["helm"]["valuesObject"]["defaultBackend"]
    assert lab == real
    assert "platform/lab/ingress-nginx-application.yaml" in generator_paths(
        appsets("platform/lab")["lab-platform"]["generators"]
    )
