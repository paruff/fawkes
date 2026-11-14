"""Guard: what an ApplicationSet git `files` generator lists must exist and fit its template.

A renamed or deleted file makes the ApplicationSet silently generate one fewer
Application (issue #2118). Nothing fails, the component just stops reconciling.
"""

import re
from collections import Counter
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
GLOB_CHARS = ("*", "?", "[", "{")
# A bare `{{ .a.b }}` lookup; `dig` lookups carry a default and are not matched.
TEMPLATE_KEY = re.compile(r"\{\{-?\s*\.([A-Za-z0-9_.]+)\s*-?\}\}")


def load_applicationsets(root: Path) -> list[tuple[Path, dict[str, Any]]]:
    found: list[tuple[Path, dict[str, Any]]] = []
    bootstrap = root / "platform" / "bootstrap"
    for file in sorted([*bootstrap.glob("*.yaml"), *bootstrap.glob("*.yml")]):
        for doc in yaml.safe_load_all(file.read_text()):
            if isinstance(doc, dict) and doc.get("kind") == "ApplicationSet":
                found.append((file, doc))
    return found


def generator_paths(generators: Any) -> list[str]:
    paths: list[str] = []
    for gen in generators or []:
        if not isinstance(gen, dict):
            continue
        for entry in (gen.get("git") or {}).get("files") or []:
            if isinstance(entry, dict) and isinstance(entry.get("path"), str):
                paths.append(entry["path"])
        # matrix and merge generators nest their own generators list
        for nested in ("matrix", "merge"):
            paths += generator_paths((gen.get(nested) or {}).get("generators"))
    return paths


def checked_paths(root: Path) -> list[tuple[Path, str, str]]:
    """(file, ApplicationSet name, path) for every non-glob generator path."""
    return [
        (file, str((doc.get("metadata") or {}).get("name")), path)
        for file, doc in load_applicationsets(root)
        for path in generator_paths((doc.get("spec") or {}).get("generators"))
        if not any(c in path for c in GLOB_CHARS)
    ]


def missing_paths(root: Path) -> list[str]:
    return [
        f"{file.relative_to(root)} (ApplicationSet {name}): {path}"
        for file, name, path in checked_paths(root)
        if not (root / path).is_file()
    ]


def first_document(file: Path) -> dict[str, Any]:
    return next((d for d in yaml.safe_load_all(file.read_text()) if isinstance(d, dict)), {})


def lookup(doc: Any, dotted: str) -> bool:
    for part in dotted.split("."):
        if not isinstance(doc, dict) or part not in doc:
            return False
        doc = doc[part]
    return True


def missing_template_keys(root: Path) -> list[str]:
    """Keys the template reads without a default that a listed file doesn't have.

    Both ApplicationSets set `missingkey=error`, so one such file stops the
    ApplicationSet from generating any Application, not only its own.
    """
    problems: list[str] = []
    for file, doc in load_applicationsets(root):
        keys = sorted(set(TEMPLATE_KEY.findall(yaml.safe_dump(doc.get("spec", {}).get("template")))))
        for _, _, path in checked_paths(root):
            if path not in generator_paths((doc.get("spec") or {}).get("generators")) or not (root / path).is_file():
                continue
            params = first_document(root / path)
            problems += [f"{file.relative_to(root)}: {path} has no .{key}" for key in keys if not lookup(params, key)]
    return problems


def duplicate_application_names(root: Path) -> list[str]:
    """Names generated more than once: two generators would fight over one Application."""
    names: Counter[str] = Counter()
    for _, _, path in checked_paths(root):
        if (root / path).is_file():
            params = first_document(root / path)
            if lookup(params, "metadata.name"):
                names[params["metadata"]["name"]] += 1
    return sorted(name for name, count in names.items() if count > 1)


def test_generator_paths_exist() -> None:
    missing = missing_paths(REPO_ROOT)
    assert not missing, "ApplicationSet generator paths missing on disk:\n" + "\n".join(missing)


def test_generator_files_supply_every_template_key() -> None:
    problems = missing_template_keys(REPO_ROOT)
    assert not problems, "missingkey=error would stop the whole ApplicationSet:\n" + "\n".join(problems)


def test_generated_application_names_are_unique() -> None:
    assert not duplicate_application_names(REPO_ROOT)


def test_real_repo_is_actually_checked() -> None:
    assert load_applicationsets(REPO_ROOT), "no ApplicationSet found under platform/bootstrap"
    assert checked_paths(REPO_ROOT), "no non-glob generator path was checked"


def write_bootstrap(root: Path, text: str) -> None:
    bootstrap = root / "platform" / "bootstrap"
    bootstrap.mkdir(parents=True)
    (bootstrap / "appset.yaml").write_text(text)


def appset(files: str, kind: str = "ApplicationSet") -> str:
    return f"kind: {kind}\nmetadata:\n  name: demo\nspec:\n  generators:\n{files}\n"


def test_missing_path_is_reported(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, appset("    - git:\n        files:\n          - path: apps/nope.yaml"))
    assert missing_paths(tmp_path) == ["platform/bootstrap/appset.yaml (ApplicationSet demo): apps/nope.yaml"]


def test_existing_path_passes(tmp_path: Path) -> None:
    (tmp_path / "apps").mkdir()
    (tmp_path / "apps" / "ok.yaml").write_text("x: 1\n")
    write_bootstrap(tmp_path, appset("    - git:\n        files:\n          - path: apps/ok.yaml"))
    assert missing_paths(tmp_path) == []


def test_glob_path_is_not_reported(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, appset("    - git:\n        files:\n          - path: apps/*/app.yaml"))
    assert missing_paths(tmp_path) == []


def test_matrix_nested_path_is_checked(tmp_path: Path) -> None:
    gens = "    - matrix:\n        generators:\n          - git:\n              files:\n                - path: apps/nested.yaml"
    write_bootstrap(tmp_path, appset(gens))
    assert len(missing_paths(tmp_path)) == 1


def test_multi_document_file_with_second_appset(tmp_path: Path) -> None:
    text = "kind: Application\nmetadata:\n  name: first\n---\n" + appset(
        "    - git:\n        files:\n          - path: apps/x.yaml"
    )
    write_bootstrap(tmp_path, text)
    assert len(missing_paths(tmp_path)) == 1


def test_non_applicationset_is_ignored(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, appset("    - git:\n        files:\n          - path: apps/x.yaml", kind="Application"))
    assert missing_paths(tmp_path) == []


TEMPLATED = """kind: ApplicationSet
metadata:
  name: demo
spec:
  generators:
    - git:
        files:
          - path: apps/a.yaml
          - path: apps/b.yaml
  template:
    metadata:
      name: "{{ .metadata.name }}"
    spec:
      project: '{{ dig "spec" "project" "default" . }}'
      source:
        targetRevision: "{{ .spec.source.targetRevision }}"
"""


def test_file_without_a_template_key_is_reported(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, TEMPLATED)
    (tmp_path / "apps").mkdir()
    (tmp_path / "apps" / "a.yaml").write_text("metadata: {name: a}\nspec: {source: {targetRevision: v1}}\n")
    (tmp_path / "apps" / "b.yaml").write_text("metadata: {name: b}\nspec: {source: {}}\n")
    assert missing_template_keys(tmp_path) == [
        "platform/bootstrap/appset.yaml: apps/b.yaml has no .spec.source.targetRevision"
    ]


def test_duplicate_application_name_is_reported(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, TEMPLATED)
    (tmp_path / "apps").mkdir()
    for name in ("a", "b"):
        (tmp_path / "apps" / f"{name}.yaml").write_text(
            "metadata: {name: same}\nspec: {source: {targetRevision: v1}}\n"
        )
    assert duplicate_application_names(tmp_path) == ["same"]


def test_null_keys_do_not_crash(tmp_path: Path) -> None:
    write_bootstrap(tmp_path, "---\n---\nkind: ApplicationSet\nspec:\n  generators:\n    - git:\n    - matrix:\n")
    assert missing_paths(tmp_path) == []
