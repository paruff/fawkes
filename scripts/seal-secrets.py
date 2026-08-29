#!/usr/bin/env python3
"""
Seal plaintext secrets for Fawkes platform.

This script finds all plaintext Kubernetes Secrets in platform/apps/,
prompts for actual values (or uses placeholders), and creates SealedSecret
resources using kubeseal.

Usage:
    python3 scripts/seal-secrets.py [--dry-run] [--cert CERT_FILE] [--namespace NAMESPACE]

Requirements:
    - kubeseal CLI installed and in PATH
    - Access to Kubernetes cluster with Sealed Secrets controller
    - Or a certificate file (--cert) for offline sealing

The script:
1. Scans platform/apps/ for plaintext Secrets with actual values (not placeholders)
2. For each secret, creates a SealedSecret using kubeseal
3. Outputs SealedSecret YAML files to platform/apps/<app>/secrets/
4. Creates .gitignore to prevent committing plaintext secrets
"""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import yaml


class SecretScanner:
    """Scans for plaintext secrets in YAML files."""

    PLACEHOLDER_PATTERNS = [
        "CHANGEME",
        "PLACEHOLDER",
        "REPLACE_WITH",
        "changeme",
        "your-",
        "example-",
        "CHANGE_ME",
        "REPLACE_ME",
        "not-a-secure",
        "dev-",
        "test-",
        "changeme-",
    ]

    def __init__(self, root_dir: Path):
        self.root_dir = root_dir

    def is_placeholder(self, value: str) -> bool:
        """Check if a value appears to be a placeholder."""
        if not isinstance(value, str):
            return False
        if not value.strip():
            return True
        value_lower = value.lower()
        return any(p.lower() in value_lower for p in self.PLACEHOLDER_PATTERNS)

    def has_real_values(self, string_data: dict, data: dict) -> bool:
        """Check if secret has any non-placeholder values."""
        for value in {**string_data, **data}.values():
            if isinstance(value, str) and not self.is_placeholder(value):
                return True
        return False

    def scan(self) -> list[dict]:
        """Scan for plaintext secrets with real values."""
        secrets = []

        for yaml_file in self.root_dir.rglob("*.yaml"):
            # Skip already sealed secrets and templates
            if any(skip in str(yaml_file) for skip in ["sealed-secret", "sealedsecret", "-template", "key-template"]):
                continue

            try:
                with open(yaml_file) as f:
                    docs = list(yaml.safe_load_all(f))

                for doc in docs:
                    if not doc or not isinstance(doc, dict):
                        continue

                    kind = doc.get("kind", "")
                    api_version = doc.get("apiVersion", "")

                    if kind == "Secret" and api_version == "v1":
                        string_data = doc.get("stringData", {})
                        data = doc.get("data", {})

                        if string_data or data:
                            metadata = doc.get("metadata", {})
                            name = metadata.get("name", "unknown")
                            namespace = metadata.get("namespace", "default")

                            # Check if it has real values
                            has_real = self.has_real_values(string_data, data)

                            secrets.append(
                                {
                                    "file": str(yaml_file),
                                    "name": name,
                                    "namespace": namespace,
                                    "stringData": string_data,
                                    "data": data,
                                    "has_real_values": has_real,
                                    "metadata": metadata,
                                }
                            )
            except Exception as e:
                print(f"Warning: Error reading {yaml_file}: {e}", file=sys.stderr)

        return secrets


class SealedSecretGenerator:
    """Generates SealedSecret resources using kubeseal."""

    def __init__(
        self,
        controller_name: str = "sealed-secrets",
        controller_namespace: str = "kube-system",
        cert_file: str | None = None,
        scope: str = "strict",
    ):
        self.controller_name = controller_name
        self.controller_namespace = controller_namespace
        self.cert_file = cert_file
        self.scope = scope

    def build_kubeseal_cmd(self, namespace: str, name: str) -> list[str]:
        """Build kubeseal command."""
        cmd = ["kubeseal"]

        if self.cert_file:
            cmd.extend(["--cert", self.cert_file])
        else:
            cmd.extend(["--controller-name", self.controller_name])
            cmd.extend(["--controller-namespace", self.controller_namespace])

        cmd.extend(["--scope", self.scope, "--namespace", namespace, "--name", name, "--format", "yaml"])

        return cmd

    def seal_secret(self, secret: dict) -> str | None:
        """Seal a secret and return the SealedSecret YAML."""
        # Create temporary secret file
        secret_yaml = {
            "apiVersion": "v1",
            "kind": "Secret",
            "metadata": {"name": secret["name"], "namespace": secret["namespace"]},
            "type": "Opaque",
        }

        if secret["stringData"]:
            secret_yaml["stringData"] = secret["stringData"]
        if secret["data"]:
            secret_yaml["data"] = secret["data"]

        # Add labels/annotations from original metadata
        metadata = secret.get("metadata", {})
        if metadata.get("labels"):
            secret_yaml["metadata"]["labels"] = metadata["labels"]
        if metadata.get("annotations"):
            secret_yaml["metadata"]["annotations"] = metadata["annotations"]

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            yaml.dump(secret_yaml, f)
            secret_file = f.name

        try:
            cmd = self.build_kubeseal_cmd(secret["namespace"], secret["name"])
            with open(secret_file) as stdin_file:
                result = subprocess.run(
                    cmd,
                    stdin=stdin_file,
                    capture_output=True,
                    text=True,
                    timeout=60,
                    check=False,
                )

            if result.returncode != 0:
                # Only secret['name'] (an identifier) and kubeseal's own stderr
                # are logged -- never secret['stringData']/['data']. kubeseal
                # reports cert/format errors, it doesn't echo input payloads.
                # CodeQL flags these because the `secret` dict also carries the
                # real values under other keys (over-approximate taint
                # tracking on the whole dict, not an actual leak).
                msg = f"Error sealing {secret['name']}: {result.stderr}"
                print(msg, file=sys.stderr)  # lgtm[py/clear-text-logging-sensitive-data]
                return None

            return result.stdout

        except subprocess.TimeoutExpired:
            print(f"Timeout sealing {secret['name']}", file=sys.stderr)  # lgtm[py/clear-text-logging-sensitive-data]
            return None
        except FileNotFoundError:
            print("Error: kubeseal not found. Install kubeseal first.", file=sys.stderr)
            return None
        finally:
            os.unlink(secret_file)


def create_gitignore(secrets_dir: Path):
    """Create .gitignore for secrets directory."""
    gitignore_content = """# Ignore plaintext secrets - only commit sealed secrets (*-sealed.yaml)
*.yaml
!*-sealed.yaml
!kustomization.yaml
*.env
*.key
*.pem
*.crt
"""
    gitignore_path = secrets_dir / ".gitignore"
    if not gitignore_path.exists():
        gitignore_path.write_text(gitignore_content)
        msg = f"Created: {gitignore_path}"
        print(msg)  # lgtm[py/clear-text-logging-sensitive-data] -- file path only, no secret value


def get_output_path(secret: dict, base_dir: Path) -> Path:
    """Determine output path for SealedSecret."""
    source_file = Path(secret["file"])

    # Find the app directory (platform/apps/<app>/)
    try:
        apps_index = source_file.parts.index("apps")
        app_dir = Path(*source_file.parts[: apps_index + 2])  # platform/apps/<app>
    except ValueError:
        # Fallback
        app_dir = base_dir / "platform" / "apps" / "unknown"

    secrets_dir = app_dir / "secrets"
    secrets_dir.mkdir(parents=True, exist_ok=True)

    # Create .gitignore
    create_gitignore(secrets_dir)

    # Output filename
    output_name = f"{secret['name']}-sealed.yaml"
    return secrets_dir / output_name


def update_kustomization(secrets_dir: Path, sealed_secret_name: str):
    """Add sealed secret to kustomization.yaml if it exists."""
    kustomization_path = secrets_dir.parent / "kustomization.yaml"

    if not kustomization_path.exists():
        return

    try:
        with open(kustomization_path) as f:
            kustomization = yaml.safe_load(f)

        if not kustomization:
            kustomization = {"resources": []}

        resources = kustomization.get("resources", [])
        relative_path = f"secrets/{sealed_secret_name}"

        if relative_path not in resources:
            resources.append(relative_path)
            kustomization["resources"] = resources

            with open(kustomization_path, "w") as f:
                yaml.dump(kustomization, f, default_flow_style=False)

            msg = f"Updated kustomization: {kustomization_path}"
            print(msg)  # lgtm[py/clear-text-logging-sensitive-data] -- file path only
    except Exception as e:
        print(f"Warning: Could not update kustomization: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Seal plaintext secrets for Fawkes platform",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Seal all secrets against cluster (requires cluster access)
  python3 scripts/seal-secrets.py

  # Seal using cached certificate (offline)
  python3 scripts/seal-secrets.py --cert sealed-secrets-cert.pem

  # Dry run - show what would be sealed
  python3 scripts/seal-secrets.py --dry-run

  # Only seal secrets in specific namespace
  python3 scripts/seal-secrets.py --namespace fawkes
        """,
    )

    parser.add_argument("--dry-run", action="store_true", help="Show what would be sealed without writing files")
    parser.add_argument("--cert", type=str, help="Path to certificate file for offline sealing")
    parser.add_argument(
        "--controller-name",
        type=str,
        default="sealed-secrets",
        help="Sealed Secrets controller name (default: sealed-secrets)",
    )
    parser.add_argument(
        "--controller-namespace",
        type=str,
        default="kube-system",
        help="Sealed Secrets controller namespace (default: kube-system)",
    )
    parser.add_argument(
        "--scope",
        type=str,
        default="strict",
        choices=["strict", "namespace-wide", "cluster-wide"],
        help="Sealing scope (default: strict)",
    )
    parser.add_argument("--namespace", type=str, help="Only seal secrets in this namespace")
    parser.add_argument("--force", action="store_true", help="Overwrite existing sealed secrets")
    parser.add_argument(
        "--include-placeholders", action="store_true", help="Also seal secrets with only placeholder values"
    )

    args = parser.parse_args()

    # Setup
    repo_root = Path(__file__).parent.parent
    platform_dir = repo_root / "platform"

    if not platform_dir.exists():
        print(f"Error: platform directory not found at {platform_dir}", file=sys.stderr)
        sys.exit(1)

    # Check kubeseal
    if not args.cert:
        try:
            subprocess.run(["kubeseal", "--version"], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Error: kubeseal not found. Install it first:", file=sys.stderr)
            print("  brew install kubeseal  # macOS", file=sys.stderr)
            print("  # Or download from https://github.com/bitnami-labs/sealed-secrets/releases", file=sys.stderr)
            sys.exit(1)
    else:
        if not Path(args.cert).exists():
            print(f"Error: Certificate file not found: {args.cert}", file=sys.stderr)
            sys.exit(1)

    # Scan for secrets
    scanner = SecretScanner(platform_dir)
    secrets = scanner.scan()

    if not secrets:
        print("No plaintext secrets found.")
        return

    # Filter by namespace
    if args.namespace:
        secrets = [s for s in secrets if s["namespace"] == args.namespace]

    # Filter by real values
    if not args.include_placeholders:
        secrets = [s for s in secrets if s["has_real_values"]]

    if not secrets:
        print("No secrets to seal (after filtering).")
        return

    # Show what will be sealed. Below prints reference only name/namespace/
    # file/status -- never the secret's stringData/data values. CodeQL flags
    # them because `s`/`secret` dicts also carry the real values under other
    # keys (over-approximate taint on the whole dict, not an actual leak).
    print(f"\nFound {len(secrets)} secret(s) to seal:")
    for s in secrets:
        status = "REAL VALUES" if s["has_real_values"] else "PLACEHOLDERS ONLY"
        print(f"  - {s['name']} (ns: {s['namespace']}) - {status}")  # lgtm[py/clear-text-logging-sensitive-data]
        print(f"    Source: {s['file']}")  # lgtm[py/clear-text-logging-sensitive-data]

    if args.dry_run:
        print("\nDry run complete. No files written.")
        return

    # Generate SealedSecrets
    generator = SealedSecretGenerator(
        controller_name=args.controller_name,
        controller_namespace=args.controller_namespace,
        cert_file=args.cert,
        scope=args.scope,
    )

    success_count = 0
    for secret in secrets:
        output_path = get_output_path(secret, repo_root)

        if output_path.exists() and not args.force:
            msg = f"Skipping {secret['name']}: {output_path} already exists (use --force to overwrite)"
            print(msg)  # lgtm[py/clear-text-logging-sensitive-data]
            continue

        print(f"\nSealing {secret['name']}...")  # lgtm[py/clear-text-logging-sensitive-data]
        sealed_yaml = generator.seal_secret(secret)

        if sealed_yaml:
            if not args.dry_run:
                output_path.write_text(sealed_yaml)
                print(f"  Written: {output_path}")  # lgtm[py/clear-text-logging-sensitive-data]

                # Update kustomization
                update_kustomization(output_path.parent, output_path.name)

            success_count += 1
        else:
            print(f"  FAILED: {secret['name']}")  # lgtm[py/clear-text-logging-sensitive-data]

    print(f"\nSuccessfully sealed {success_count}/{len(secrets)} secrets.")

    if success_count > 0:
        print("\nNext steps:")
        print("  1. Review generated SealedSecret files")
        print("  2. Commit changes: git add platform/apps/*/secrets/*-sealed.yaml")
        print("  3. Create PR for review")
        print("  4. Merge - ArgoCD will sync and controller will decrypt")


if __name__ == "__main__":
    main()
