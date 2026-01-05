#!/usr/bin/env python3
"""
Script to help standardize Kubernetes manifests according to Fawkes standards.
Adds standard labels, annotations, security contexts where missing.
"""

import sys
import yaml
from pathlib import Path
from typing import Dict, Any, List


def ensure_standard_labels(resource: Dict[str, Any], app_name: str, component: str = None, version: str = None) -> None:
    """Add standard labels to a Kubernetes resource."""
    if "metadata" not in resource:
        resource["metadata"] = {}
    if "labels" not in resource["metadata"]:
        resource["metadata"]["labels"] = {}
    
    labels = resource["metadata"]["labels"]
    
    # Required labels
    if "app.kubernetes.io/name" not in labels:
        labels["app.kubernetes.io/name"] = app_name
    if "app.kubernetes.io/part-of" not in labels:
        labels["app.kubernetes.io/part-of"] = "fawkes"
    
    # Legacy compatibility
    if "app" not in labels:
        labels["app"] = app_name
    
    # Optional labels
    if component and "app.kubernetes.io/component" not in labels:
        labels["app.kubernetes.io/component"] = component
    if version and "app.kubernetes.io/version" not in labels:
        labels["app.kubernetes.io/version"] = version


def ensure_prometheus_annotations(resource: Dict[str, Any], port: str = "8000", path: str = "/metrics") -> None:
    """Add Prometheus scraping annotations to Deployment pod template."""
    if resource.get("kind") != "Deployment":
        return
    
    spec = resource.get("spec", {})
    template = spec.get("template", {})
    
    if "metadata" not in template:
        template["metadata"] = {}
    if "annotations" not in template["metadata"]:
        template["metadata"]["annotations"] = {}
    
    annotations = template["metadata"]["annotations"]
    
    if "prometheus.io/scrape" not in annotations:
        annotations["prometheus.io/scrape"] = "true"
    if "prometheus.io/port" not in annotations:
        annotations["prometheus.io/port"] = port
    if "prometheus.io/path" not in annotations:
        annotations["prometheus.io/path"] = path


def ensure_pod_security_context(resource: Dict[str, Any]) -> None:
    """Ensure pod-level security context is set."""
    if resource.get("kind") not in ["Deployment", "CronJob"]:
        return
    
    spec = resource.get("spec", {})
    if resource.get("kind") == "CronJob":
        template_spec = spec.get("jobTemplate", {}).get("spec", {}).get("template", {}).get("spec", {})
    else:
        template_spec = spec.get("template", {}).get("spec", {})
    
    if not template_spec:
        return
    
    if "securityContext" not in template_spec:
        template_spec["securityContext"] = {}
    
    sec_ctx = template_spec["securityContext"]
    
    if "runAsNonRoot" not in sec_ctx:
        sec_ctx["runAsNonRoot"] = True
    if "runAsUser" not in sec_ctx:
        sec_ctx["runAsUser"] = 65534
    if "runAsGroup" not in sec_ctx:
        sec_ctx["runAsGroup"] = 65534
    if "fsGroup" not in sec_ctx:
        sec_ctx["fsGroup"] = 65534


def ensure_container_security_context(container: Dict[str, Any]) -> None:
    """Ensure container-level security context is set."""
    if "securityContext" not in container:
        container["securityContext"] = {}
    
    sec_ctx = container["securityContext"]
    
    if "allowPrivilegeEscalation" not in sec_ctx:
        sec_ctx["allowPrivilegeEscalation"] = False
    if "readOnlyRootFilesystem" not in sec_ctx:
        sec_ctx["readOnlyRootFilesystem"] = True
    if "runAsNonRoot" not in sec_ctx:
        sec_ctx["runAsNonRoot"] = True
    if "runAsUser" not in sec_ctx:
        sec_ctx["runAsUser"] = 65534
    if "capabilities" not in sec_ctx:
        sec_ctx["capabilities"] = {}
    if "drop" not in sec_ctx["capabilities"]:
        sec_ctx["capabilities"]["drop"] = ["ALL"]
    if "seccompProfile" not in sec_ctx:
        sec_ctx["seccompProfile"] = {"type": "RuntimeDefault"}


def check_resource_limits(container: Dict[str, Any]) -> List[str]:
    """Check if resource limits are defined."""
    warnings = []
    
    if "resources" not in container:
        warnings.append(f"Container '{container.get('name', 'unknown')}' missing resource limits")
    else:
        resources = container["resources"]
        if "requests" not in resources:
            warnings.append(f"Container '{container.get('name', 'unknown')}' missing resource requests")
        if "limits" not in resources:
            warnings.append(f"Container '{container.get('name', 'unknown')}' missing resource limits")
    
    return warnings


def check_health_checks(container: Dict[str, Any]) -> List[str]:
    """Check if health checks are defined."""
    warnings = []
    
    if "livenessProbe" not in container:
        warnings.append(f"Container '{container.get('name', 'unknown')}' missing livenessProbe")
    if "readinessProbe" not in container:
        warnings.append(f"Container '{container.get('name', 'unknown')}' missing readinessProbe")
    
    return warnings


def analyze_manifest(file_path: Path) -> Dict[str, Any]:
    """Analyze a manifest file and return findings."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Load all YAML documents
    documents = list(yaml.safe_load_all(content))
    
    findings = {
        "file": str(file_path),
        "resources": [],
        "warnings": []
    }
    
    for doc in documents:
        if not doc or not isinstance(doc, dict):
            continue
        
        resource_findings = {
            "kind": doc.get("kind", "Unknown"),
            "name": doc.get("metadata", {}).get("name", "Unknown"),
            "issues": []
        }
        
        # Check labels
        labels = doc.get("metadata", {}).get("labels", {})
        if "app.kubernetes.io/name" not in labels:
            resource_findings["issues"].append("Missing standard label: app.kubernetes.io/name")
        if "app.kubernetes.io/part-of" not in labels:
            resource_findings["issues"].append("Missing standard label: app.kubernetes.io/part-of")
        
        # Check Deployments
        if doc.get("kind") == "Deployment":
            spec = doc.get("spec", {})
            template_spec = spec.get("template", {}).get("spec", {})
            
            # Check pod security context
            if "securityContext" not in template_spec:
                resource_findings["issues"].append("Missing pod-level security context")
            else:
                sec_ctx = template_spec["securityContext"]
                if not sec_ctx.get("runAsNonRoot"):
                    resource_findings["issues"].append("Pod security context missing runAsNonRoot: true")
            
            # Check containers
            containers = template_spec.get("containers", [])
            for container in containers:
                # Check container security context
                if "securityContext" not in container:
                    resource_findings["issues"].append(f"Container '{container.get('name')}' missing security context")
                else:
                    sec_ctx = container["securityContext"]
                    if "seccompProfile" not in sec_ctx:
                        resource_findings["issues"].append(f"Container '{container.get('name')}' missing seccompProfile")
                
                # Check resources
                resource_findings["issues"].extend(check_resource_limits(container))
                
                # Check health checks
                resource_findings["issues"].extend(check_health_checks(container))
        
        if resource_findings["issues"]:
            findings["resources"].append(resource_findings)
    
    return findings


def main():
    if len(sys.argv) < 2:
        print("Usage: python standardize-k8s-manifest.py <manifest-file> [--analyze-only]")
        sys.exit(1)
    
    file_path = Path(sys.argv[1])
    analyze_only = "--analyze-only" in sys.argv
    
    if not file_path.exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    
    if analyze_only:
        findings = analyze_manifest(file_path)
        print(f"\n=== Analysis of {findings['file']} ===\n")
        
        if not findings["resources"]:
            print("✅ No issues found!")
        else:
            for resource in findings["resources"]:
                print(f"\n{resource['kind']}: {resource['name']}")
                for issue in resource["issues"]:
                    print(f"  ⚠️  {issue}")
        
        sys.exit(0)
    
    print(f"This is a helper script. Manual updates recommended.")
    print(f"Run with --analyze-only to see what needs to be standardized.")


if __name__ == "__main__":
    main()
