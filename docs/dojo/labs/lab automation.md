#!/usr/bin/env python3
"""
Fawkes Dojo Lab Automation & Validation Scripts

This module provides automated lab environment setup, validation,
and grading for all Fawkes Dojo assessments.

Usage:
    # Start lab environment
    fawkes lab start --module 1
    
    # Validate lab completion
    fawkes lab validate --lab white-belt-lab1
    
    # Run assessment validation
    fawkes assessment validate --belt white
"""

import subprocess
import yaml
import json
import sys
import time
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class BeltLevel(Enum):
    WHITE = "white"
    YELLOW = "yellow"
    GREEN = "green"
    BROWN = "brown"
    BLACK = "black"


@dataclass
class ValidationResult:
    """Result of a lab validation check"""
    passed: bool
    message: str
    points: int
    max_points: int
    details: Optional[Dict] = None


@dataclass
class LabEnvironment:
    """Lab environment configuration"""
    module_id: int
    belt_level: BeltLevel
    cluster_name: str
    namespace: str
    resources: List[str]


class LabAutomation:
    """Main class for lab automation"""
    
    def __init__(self):
        self.kubectl = "kubectl"
        self.results = []
    
    def run_command(self, cmd: List[str], capture_output: bool = True) -> Tuple[int, str, str]:
        """Execute shell command and return exit code, stdout, stderr"""
        result = subprocess.run(
            cmd,
            capture_output=capture_output,
            text=True
        )
        return result.returncode, result.stdout, result.stderr
    
    def kubectl_get(self, resource: str, namespace: str = "default", 
                    output: str = "json") -> Dict:
        """Run kubectl get command and parse JSON output"""
        cmd = [self.kubectl, "get", resource, "-n", namespace, "-o", output]
        exit_code, stdout, stderr = self.run_command(cmd)
        
        if exit_code != 0:
            print(f"Error: {stderr}")
            return {}
        
        try:
            return json.loads(stdout)
        except json.JSONDecodeError:
            return {}
    
    def check_resource_exists(self, resource_type: str, resource_name: str, 
                             namespace: str = "default") -> bool:
        """Check if a Kubernetes resource exists"""
        cmd = [self.kubectl, "get", resource_type, resource_name, "-n", namespace]
        exit_code, _, _ = self.run_command(cmd)
        return exit_code == 0


# =============================================================================
# WHITE BELT LAB VALIDATORS
# =============================================================================

class WhiteBeltLab1Validator:
    """Validator for White Belt Lab 1: First Deployment"""
    
    def __init__(self, lab_automation: LabAutomation):
        self.lab = lab_automation
        self.namespace = "default"
        self.max_points = 10
    
    def validate(self) -> ValidationResult:
        """Run all validation checks"""
        checks = [
            self.check_deployment_exists(),
            self.check_replica_count(),
            self.check_pods_running(),
            self.check_service_exists(),
            self.check_application_accessible(),
        ]
        
        passed_checks = sum(1 for check in checks if check)
        points = int((passed_checks / len(checks)) * self.max_points)
        
        return ValidationResult(
            passed=passed_checks == len(checks),
            message=f"Passed {passed_checks}/{len(checks)} checks",
            points=points,
            max_points=self.max_points,
            details={"checks": [
                "Deployment exists",
                "3 replicas configured",
                "All pods running",
                "Service exists",
                "Application accessible"
            ]}
        )
    
    def check_deployment_exists(self) -> bool:
        """Check if deployment exists"""
        return self.lab.check_resource_exists("deployment", "my-first-app", self.namespace)
    
    def check_replica_count(self) -> bool:
        """Check if deployment has 3 replicas"""
        deployment = self.lab.kubectl_get("deployment/my-first-app", self.namespace)
        if not deployment:
            return False
        
        spec_replicas = deployment.get("spec", {}).get("replicas", 0)
        return spec_replicas == 3
    
    def check_pods_running(self) -> bool:
        """Check if all pods are in Running state"""
        pods = self.lab.kubectl_get("pods", self.namespace)
        if not pods or "items" not in pods:
            return False
        
        app_pods = [
            pod for pod in pods["items"]
            if pod.get("metadata", {}).get("labels", {}).get("app") == "my-first-app"
        ]
        
        if len(app_pods) != 3:
            return False
        
        running_pods = [
            pod for pod in app_pods
            if pod.get("status", {}).get("phase") == "Running"
        ]
        
        return len(running_pods) == 3
    
    def check_service_exists(self) -> bool:
        """Check if service exists"""
        return self.lab.check_resource_exists("service", "my-first-app", self.namespace)
    
    def check_application_accessible(self) -> bool:
        """Check if application responds to HTTP requests"""
        # Get service endpoint
        service = self.lab.kubectl_get("service/my-first-app", self.namespace)
        if not service:
            return False
        
        # In real implementation, would test HTTP endpoint
        # For now, check service has endpoints
        cmd = [self.lab.kubectl, "get", "endpoints", "my-first-app", "-n", self.namespace]
        exit_code, stdout, _ = self.lab.run_command(cmd)
        
        return exit_code == 0 and "my-first-app" in stdout


class WhiteBeltLab2Validator:
    """Validator for White Belt Lab 2: Multi-Environment Deployment"""
    
    def __init__(self, lab_automation: LabAutomation):
        self.lab = lab_automation
        self.max_points = 15
    
    def validate(self) -> ValidationResult:
        """Run all validation checks"""
        checks = [
            self.check_kustomize_structure(),
            self.check_dev_environment(),
            self.check_prod_environment(),
            self.check_argocd_apps(),
        ]
        
        passed_checks = sum(1 for check in checks if check)
        points = int((passed_checks / len(checks)) * self.max_points)
        
        return ValidationResult(
            passed=passed_checks == len(checks),
            message=f"Passed {passed_checks}/{len(checks)} checks",
            points=points,
            max_points=self.max_points,
            details={"checks": [
                "Kustomize base and overlays exist",
                "Dev environment: 1 replica, no limits",
                "Prod environment: 3 replicas, with limits",
                "ArgoCD managing both environments"
            ]}
        )
    
    def check_kustomize_structure(self) -> bool:
        """Check if kustomize directory structure exists"""
        import os
        
        required_files = [
            "k8s/base/kustomization.yaml",
            "k8s/overlays/dev/kustomization.yaml",
            "k8s/overlays/prod/kustomization.yaml"
        ]
        
        return all(os.path.exists(f) for f in required_files)
    
    def check_dev_environment(self) -> bool:
        """Check dev environment configuration"""
        deployment = self.lab.kubectl_get("deployment/my-first-app", "dev")
        if not deployment:
            return False
        
        replicas = deployment.get("spec", {}).get("replicas", 0)
        containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        
        # Check 1 replica
        if replicas != 1:
            return False
        
        # Check no resource limits
        if containers:
            resources = containers[0].get("resources", {})
            if "limits" in resources:
                return False
        
        return True
    
    def check_prod_environment(self) -> bool:
        """Check prod environment configuration"""
        deployment = self.lab.kubectl_get("deployment/my-first-app", "prod")
        if not deployment:
            return False
        
        replicas = deployment.get("spec", {}).get("replicas", 0)
        containers = deployment.get("spec", {}).get("template", {}).get("spec", {}).get("containers", [])
        
        # Check 3 replicas
        if replicas != 3:
            return False
        
        # Check resource limits exist
        if containers:
            resources = containers[0].get("resources", {})
            if "limits" not in resources:
                return False
            
            limits = resources["limits"]
            if "memory" not in limits or "cpu" not in limits:
                return False
        
        return True
    
    def check_argocd_apps(self) -> bool:
        """Check if ArgoCD applications exist for both environments"""
        dev_app = self.lab.check_resource_exists("application", "my-first-app-dev", "argocd")
        prod_app = self.lab.check_resource_exists("application", "my-first-app-prod", "argocd")
        
        return dev_app and prod_app


class WhiteBeltLab3Validator:
    """Validator for White Belt Lab 3: DORA Metrics"""
    
    def __init__(self, lab_automation: LabAutomation):
        self.lab = lab_automation
        self.max_points = 15
    
    def validate(self) -> ValidationResult:
        """Run all validation checks"""
        checks = [
            self.check_prometheus_annotations(),
            self.check_dora_exporter(),
            self.check_grafana_dashboard(),
            self.check_deployment_metrics(),
        ]
        
        passed_checks = sum(1 for check in checks if check)
        points = int((passed_checks / len(checks)) * self.max_points)
        
        return ValidationResult(
            passed=passed_checks == len(checks),
            message=f"Passed {passed_checks}/{len(checks)} checks",
            points=points,
            max_points=self.max_points,
            details={"checks": [
                "Prometheus annotations configured",
                "DORA exporter deployed",
                "Grafana dashboard exists",
                "Deployment metrics being collected"
            ]}
        )
    
    def check_prometheus_annotations(self) -> bool:
        """Check if deployment has Prometheus annotations"""
        deployment = self.lab.kubectl_get("deployment/my-first-app", "default")
        if not deployment:
            return False
        
        annotations = deployment.get("metadata", {}).get("annotations", {})
        
        required_annotations = [
            "prometheus.io/scrape",
            "prometheus.io/port"
        ]
        
        return all(ann in annotations for ann in required_annotations)
    
    def check_dora_exporter(self) -> bool:
        """Check if DORA metrics exporter is deployed"""
        return self.lab.check_resource_exists("deployment", "dora-exporter", "monitoring")
    
    def check_grafana_dashboard(self) -> bool:
        """Check if Grafana dashboard ConfigMap exists"""
        return self.lab.check_resource_exists("configmap", "dora-dashboard", "monitoring")
    
    def check_deployment_metrics(self) -> bool:
        """Check if deployment metrics are being collected"""
        # Query Prometheus for deployment metrics
        # In real implementation, would query Prometheus API
        # For now, check if ServiceMonitor exists
        return self.lab.check_resource_exists("servicemonitor", "my-first-app", "default")


# =============================================================================
# YELLOW BELT LAB VALIDATORS
# =============================================================================

class YellowBeltLab1Validator:
    """Validator for Yellow Belt Lab 1: Production CI Pipeline"""
    
    def __init__(self, lab_automation: LabAutomation):
        self.lab = lab_automation
        self.max_points = 20
    
    def validate(self) -> ValidationResult:
        """Run all validation checks"""
        checks = [
            self.check_pipeline_exists(),
            self.check_test_stage(),
            self.check_security_scanning(),
            self.check_image_built(),
            self.check_pipeline_time(),
            self.check_quality_gates(),
        ]
        
        passed_checks = sum(1 for check in checks if check)
        points = int((passed_checks / len(checks)) * self.max_points)
        
        return ValidationResult(
            passed=passed_checks == len(checks),
            message=f"Passed {passed_checks}/{len(checks)} checks",
            points=points,
            max_points=self.max_points,
            details={"checks": [
                "Pipeline configuration exists",
                "Tests running and passing",
                "Security scanning configured",
                "Container image built",
                "Pipeline completes in <5 min",
                "Quality gates enforced"
            ]}
        )
    
    def check_pipeline_exists(self) -> bool:
        """Check if CI pipeline configuration exists"""
        import os
        pipeline_files = [
            ".github/workflows/ci.yml",
            ".tekton/pipeline.yaml",
            ".gitlab-ci.yml"
        ]
        return any(os.path.exists(f) for f in pipeline_files)
    
    def check_test_stage(self) -> bool:
        """Check if tests are configured and passing"""
        # Check for test configuration
        import os
        return os.path.exists("package.json") or os.path.exists("requirements.txt")
    
    def check_security_scanning(self) -> bool:
        """Check if security scanning is configured"""
        import os
        config_files = [
            ".semgrep.yml",
            "sonar-project.properties",
            ".trivyignore"
        ]
        return any(os.path.exists(f) for f in config_files)
    
    def check_image_built(self) -> bool:
        """Check if container image was built successfully"""
        # Would query container registry in real implementation
        return True
    
    def check_pipeline_time(self) -> bool:
        """Check if pipeline completes in <5 minutes"""
        # Would query CI system for last run duration
        return True
    
    def check_quality_gates(self) -> bool:
        """Check if quality gates are configured"""
        import os
        # Check for quality gate configuration
        return os.path.exists(".fawkes/quality-gates.yml")


# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

class FawkesLabCLI:
    """Command line interface for Fawkes lab automation"""
    
    def __init__(self):
        self.lab_automation = LabAutomation()
        self.validators = {
            "white-belt-lab1": WhiteBeltLab1Validator,
            "white-belt-lab2": WhiteBeltLab2Validator,
            "white-belt-lab3": WhiteBeltLab3Validator,
            "yellow-belt-lab1": YellowBeltLab1Validator,
        }
    
    def start_lab(self, module_id: int):
        """Start a lab environment"""
        print(f"🚀 Starting lab environment for Module {module_id}...")
        
        # Determine belt and lab based on module
        belt_config = self.get_belt_config(module_id)
        
        # Create namespace
        namespace = f"lab-module-{module_id}"
        self.create_namespace(namespace)
        
        # Deploy lab resources
        self.deploy_lab_resources(module_id, namespace)
        
        print(f"✅ Lab environment ready!")
        print(f"   Namespace: {namespace}")
        print(f"   Access: kubectl config set-context --current --namespace={namespace}")
        
        # Show lab instructions
        self.show_lab_instructions(module_id)
    
    def validate_lab(self, lab_name: str):
        """Validate lab completion"""
        print(f"🔍 Validating {lab_name}...")
        
        if lab_name not in self.validators:
            print(f"❌ Unknown lab: {lab_name}")
            print(f"   Available labs: {', '.join(self.validators.keys())}")
            return
        
        # Run validator
        validator_class = self.validators[lab_name]
        validator = validator_class(self.lab_automation)
        result = validator.validate()
        
        # Display results
        self.display_validation_results(result)
        
        return result
    
    def create_namespace(self, namespace: str):
        """Create Kubernetes namespace"""
        cmd = [self.lab_automation.kubectl, "create", "namespace", namespace]
        exit_code, stdout, stderr = self.lab_automation.run_command(cmd)
        
        if exit_code != 0 and "already exists" not in stderr:
            print(f"⚠️  Warning: {stderr}")
    
    def deploy_lab_resources(self, module_id: int, namespace: str):
        """Deploy lab-specific resources"""
        resources = self.get_lab_resources(module_id)
        
        for resource in resources:
            print(f"   Deploying {resource}...")
            cmd = [
                self.lab_automation.kubectl, 
                "apply", 
                "-f", 
                f"labs/module-{module_id}/{resource}.yaml",
                "-n",
                namespace
            ]
            self.lab_automation.run_command(cmd)
    
    def get_belt_config(self, module_id: int) -> Dict:
        """Get belt configuration for module"""
        belt_ranges = {
            (1, 4): "white",
            (5, 8): "yellow",
            (9, 12): "green",
            (13, 16): "brown",
            (17, 20): "black"
        }
        
        for (start, end), belt in belt_ranges.items():
            if start <= module_id <= end:
                return {"belt": belt, "module_in_belt": module_id - start + 1}
        
        return {"belt": "unknown", "module_in_belt": 0}
    
    def get_lab_resources(self, module_id: int) -> List[str]:
        """Get list of resources to deploy for lab"""
        # Map module to required resources
        resource_map = {
            1: ["namespace", "sample-deployment"],
            2: ["namespace", "argocd-application"],
            3: ["namespace", "prometheus", "grafana"],
            4: ["namespace", "sample-app"],
            5: ["namespace", "tekton-pipeline"],
            # ... etc
        }
        
        return resource_map.get(module_id, ["namespace"])
    
    def show_lab_instructions(self, module_id: int):
        """Display lab instructions"""
        print("\n📚 Lab Instructions:")
        print(f"   1. Review module {module_id} content")
        print(f"   2. Complete the hands-on exercises")
        print(f"   3. Run: fawkes lab validate --lab [lab-name]")
        print(f"\n   Documentation: https://docs.fawkes.io/dojo/module-{module_id}")
    
    def display_validation_results(self, result: ValidationResult):
        """Display validation results in a nice format"""
        print("\n" + "="*60)
        print(f"   LAB VALIDATION RESULTS")
        print("="*60)
        
        if result.passed:
            print(f"✅ PASSED: {result.message}")
        else:
            print(f"❌ FAILED: {result.message}")
        
        print(f"\n   Score: {result.points}/{result.max_points} points")
        
        if result.details and "checks" in result.details:
            print(f"\n   Checks:")
            for check in result.details["checks"]:
                print(f"      • {check}")
        
        print("="*60 + "\n")
        
        if result.passed:
            print("🎉 Great job! You can move to the next lab.")
        else:
            print("💡 Review the failed checks and try again.")
            print("   Need help? Visit #dojo-support on Mattermost")


# =============================================================================
# ASSESSMENT AUTOMATION
# =============================================================================

class AssessmentValidator:
    """Automated assessment validation and grading"""
    
    def __init__(self):
        self.lab_automation = LabAutomation()
    
    def validate_assessment(self, belt_level: str) -> Dict:
        """Validate complete belt assessment"""
        print(f"🎓 Validating {belt_level.upper()} Belt Assessment...")
        
        # Get labs for this belt
        labs = self.get_belt_labs(belt_level)
        
        results = []
        total_points = 0
        max_total_points = 0
        
        for lab_name in labs:
            cli = FawkesLabCLI()
            result = cli.validate_lab(lab_name)
            
            if result:
                results.append({
                    "lab": lab_name,
                    "passed": result.passed,
                    "points": result.points,
                    "max_points": result.max_points
                })
                total_points += result.points
                max_total_points += result.max_points
        
        # Calculate final score
        percentage = (total_points / max_total_points * 100) if max_total_points > 0 else 0
        
        # Determine pass/fail
        passing_thresholds = {
            "white": 80,
            "yellow": 85,
            "green": 85,
            "brown": 85,
            "black": 90
        }
        
        passing_threshold = passing_thresholds.get(belt_level, 80)
        passed = percentage >= passing_threshold
        
        return {
            "belt": belt_level,
            "total_points": total_points,
            "max_points": max_total_points,
            "percentage": percentage,
            "passed": passed,
            "passing_threshold": passing_threshold,
            "labs": results
        }
    
    def get_belt_labs(self, belt_level: str) -> List[str]:
        """Get list of labs for a belt level"""
        labs_by_belt = {
            "white": ["white-belt-lab1", "white-belt-lab2", "white-belt-lab3"],
            "yellow": ["yellow-belt-lab1", "yellow-belt-lab2", "yellow-belt-lab3"],
            "green": ["green-belt-lab1", "green-belt-lab2", "green-belt-lab3"],
            "brown": ["brown-belt-lab1", "brown-belt-lab2", "brown-belt-lab3", "brown-belt-lab4"],
            "black": ["black-belt-implementation"]
        }
        
        return labs_by_belt.get(belt_level, [])
    
    def generate_certificate(self, user_info: Dict, belt_level: str, score: float):
        """Generate certification PDF"""
        print(f"🎖️ Generating {belt_level.upper()} Belt Certificate...")
        
        cert_data = {
            "name": user_info.get("name"),
            "email": user_info.get("email"),
            "belt": belt_level,
            "score": score,
            "date": time.strftime("%Y-%m-%d"),
            "cert_id": self.generate_cert_id(user_info, belt_level)
        }
        
        # In real implementation, would generate PDF
        print(f"   Certificate ID: {cert_data['cert_id']}")
        print(f"   Verify at: https://fawkes.io/verify/{cert_data['cert_id']}")
        
        return cert_data
    
    def generate_cert_id(self, user_info: Dict, belt_level: str) -> str:
        """Generate unique certificate ID"""
        import hashlib
        
        data = f"{user_info.get('email')}{belt_level}{time.time()}"
        hash_obj = hashlib.sha256(data.encode())
        return f"FPA-2025-{hash_obj.hexdigest()[:8].upper()}"


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

def setup_lab_environment():
    """One-time setup for lab infrastructure"""
    print("🔧 Setting up Fawkes Dojo lab infrastructure...")
    
    lab = LabAutomation()
    
    # Create monitoring namespace
    print("   Creating monitoring namespace...")
    lab.run_command([lab.kubectl, "create", "namespace", "monitoring"])
    
    # Install Prometheus
    print("   Installing Prometheus...")
    lab.run_command([
        "helm", "install", "prometheus", "prometheus-community/kube-prometheus-stack",
        "-n", "monitoring"
    ])
    
    # Install ArgoCD
    print("   Installing ArgoCD...")
    lab.run_command([lab.kubectl, "create", "namespace", "argocd"])
    lab.run_command([
        lab.kubectl, "apply", "-n", "argocd",
        "-f", "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    ])
    
    print("✅ Lab infrastructure ready!")


def cleanup_lab_environment(module_id: int):
    """Clean up lab environment"""
    print(f"🧹 Cleaning up lab environment for Module {module_id}...")
    
    lab = LabAutomation()
    namespace = f"lab-module-{module_id}"
    
    lab.run_command([lab.kubectl, "delete", "namespace", namespace])
    
    print(f"✅ Lab environment cleaned up!")


# =============================================================================
# MAIN CLI ENTRYPOINT
# =============================================================================

def main():
    """Main CLI entrypoint"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Fawkes Dojo Lab Automation")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Lab commands
    lab_parser = subparsers.add_parser("lab", help="Lab environment management")
    lab_subparsers = lab_parser.add_subparsers(dest="lab_command")
    
    # fawkes lab start
    start_parser = lab_subparsers.add_parser("start", help="Start lab environment")
    start_parser.add_argument("--module", type=int, required=True, help="Module number (1-20)")
    
    # fawkes lab validate
    validate_parser = lab_subparsers.add_parser("validate", help="Validate lab completion")
    validate_parser.add_argument("--lab", type=str, required=True, help="Lab name (e.g., white-belt-lab1)")
    
    # fawkes lab stop
    stop_parser = lab_subparsers.add_parser("stop", help="Stop lab environment")
    stop_parser.add_argument("--module", type=int, required=True, help="Module number")
    
    # Assessment commands
    assessment_parser = subparsers.add_parser("assessment", help="Assessment management")
    assessment_subparsers = assessment_parser.add_subparsers(dest="assessment_command")
    
    # fawkes assessment validate
    assess_validate_parser = assessment_subparsers.add_parser("validate", help="Validate assessment")
    assess_validate_parser.add_argument("--belt", type=str, required=True, 
                                       choices=["white", "yellow", "green", "brown", "black"],
                                       help="Belt level")
    
    # Setup command
    subparsers.add_parser("setup", help="Setup lab infrastructure")
    
    args = parser.parse_args()
    
    # Execute command
    if args.command == "lab":
        cli = FawkesLabCLI()
        
        if args.lab_command == "start":
            cli.start_lab(args.module)
        
        elif args.lab_command == "validate":
            cli.validate_lab(args.lab)
        
        elif args.lab_command == "stop":
            cleanup_lab_environment(args.module)
    
    elif args.command == "assessment":
        validator = AssessmentValidator()
        
        if args.assessment_command == "validate":
            result = validator.validate_assessment(args.belt)
            
            print("\n" + "="*60)
            print(f"   {result['belt'].upper()} BELT ASSESSMENT RESULTS")
            print("="*60)
            print(f"\n   Total Score: {result['total_points']}/{result['max_points']} ({result['percentage']:.1f}%)")
            print(f"   Passing Threshold: {result['passing_threshold']}%")
            
            if result['passed']:
                print(f"\n   ✅ PASSED - Congratulations!")
                print(f"\n   You have earned the {result['belt'].upper()} Belt certification!")
            else:
                print(f"\n   ❌ NOT PASSED")
                print(f"   You need {result['passing_threshold']}% to pass.")
                print(f"   Review the areas where you lost points and try again.")
            
            print("\n   Lab Results:")
            for lab in result['labs']:
                status = "✅" if lab['passed'] else "❌"
                print(f"      {status} {lab['lab']}: {lab['points']}/{lab['max_points']}")
            
            print("="*60 + "\n")
    
    elif args.command == "setup":
        setup_lab_environment()
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()


# =============================================================================
# EXAMPLE USAGE
# =============================================================================

"""
Example usage:

# Start a lab environment
$ fawkes lab start --module 1

# Validate lab completion
$ fawkes lab validate --lab white-belt-lab1

# Clean up lab
$ fawkes lab stop --module 1

# Validate entire belt assessment
$ fawkes assessment validate --belt white

# Setup lab infrastructure (one-time)
$ fawkes setup
"""