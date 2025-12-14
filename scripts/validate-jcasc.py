#!/usr/bin/env python3
"""
Validate Jenkins Configuration as Code (JCasC) YAML files.

This script validates:
1. YAML syntax is correct
2. Required sections are present
3. Environment variables are properly referenced
4. No hardcoded credentials exist
"""

import sys
import yaml
import re
from pathlib import Path


def validate_yaml_syntax(file_path):
    """Validate YAML syntax."""
    try:
        with open(file_path, 'r') as f:
            yaml.safe_load(f)
        print(f"✅ YAML syntax valid: {file_path}")
        return True
    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error in {file_path}: {e}")
        return False


def check_required_sections(config, file_path):
    """Check that required JCasC sections are present."""
    required_sections = ['jenkins', 'securityRealm', 'authorizationStrategy']
    missing = []

    for section in required_sections:
        if section not in config:
            missing.append(section)

    if missing:
        print(f"❌ Missing required sections in {file_path}: {', '.join(missing)}")
        return False

    print(f"✅ All required sections present in {file_path}")
    return True


def check_kubernetes_cloud(config, file_path):
    """Check Kubernetes cloud configuration."""
    if 'jenkins' not in config:
        return False

    jenkins_config = config['jenkins']
    if 'clouds' not in jenkins_config:
        print(f"⚠️  No clouds configured in {file_path}")
        return True  # Not a hard requirement

    clouds = jenkins_config.get('clouds', [])
    k8s_clouds = [c for c in clouds if 'kubernetes' in c]

    if not k8s_clouds:
        print(f"⚠️  No Kubernetes cloud configured in {file_path}")
        return True

    k8s = k8s_clouds[0]['kubernetes']
    required_fields = ['name', 'namespace', 'jenkinsUrl', 'jenkinsTunnel']
    missing = [f for f in required_fields if f not in k8s]

    if missing:
        print(f"❌ Kubernetes cloud missing fields in {file_path}: {', '.join(missing)}")
        return False

    print(f"✅ Kubernetes cloud properly configured in {file_path}")
    return True


def check_environment_variables(content, file_path):
    """Check that environment variables are used for sensitive data."""
    # Pattern for environment variable substitution in JCasC
    env_var_pattern = r'\$\{[A-Z_]+\}'

    # Find all environment variable references
    env_vars = re.findall(env_var_pattern, content)

    if env_vars:
        print(f"✅ Found {len(env_vars)} environment variable references in {file_path}")
        unique_vars = set(env_vars)
        print(f"   Variables: {', '.join(sorted(unique_vars))}")
    else:
        print(f"⚠️  No environment variables found in {file_path}")

    return True


def check_no_hardcoded_credentials(content, file_path):
    """Check that no credentials are hardcoded."""
    # Patterns that might indicate hardcoded credentials
    suspicious_patterns = [
        (r'password:\s*["\'](?!.*\$\{)[^"\']{8,}["\']', 'hardcoded password'),
        (r'token:\s*["\'](?!.*\$\{)[a-zA-Z0-9]{20,}["\']', 'hardcoded token'),
        (r'secret:\s*["\'](?!.*\$\{)[a-zA-Z0-9]{20,}["\']', 'hardcoded secret'),
        (r'apiKey:\s*["\'](?!.*\$\{)[a-zA-Z0-9]{20,}["\']', 'hardcoded API key'),
    ]

    issues = []
    for pattern, description in suspicious_patterns:
        matches = re.findall(pattern, content, re.IGNORECASE)
        if matches:
            # Filter out CHANGE_ME placeholders and example values
            real_matches = [m for m in matches if 'CHANGE_ME' not in m and 'changeme' not in m.lower()]
            if real_matches:
                issues.append(description)

    if issues:
        print(f"❌ Potential hardcoded credentials in {file_path}:")
        for issue in issues:
            print(f"   - {issue}")
        return False

    print(f"✅ No hardcoded credentials detected in {file_path}")
    return True


def validate_jcasc_file(file_path):
    """Validate a single JCasC file."""
    print(f"\n{'='*70}")
    print(f"Validating: {file_path}")
    print(f"{'='*70}")

    # Read file content
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error reading file {file_path}: {e}")
        return False

    # Validate YAML syntax
    if not validate_yaml_syntax(file_path):
        return False

    # Load YAML for structure validation
    try:
        with open(file_path, 'r') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        print(f"❌ Error loading YAML from {file_path}: {e}")
        return False

    # Skip if it's a ConfigMap (check structure)
    if isinstance(config, dict) and config.get('kind') == 'ConfigMap':
        print(f"ℹ️  File is a ConfigMap, extracting JCasC data...")
        if 'data' in config and 'jcasc.yaml' in config['data']:
            # Parse the embedded YAML
            try:
                config = yaml.safe_load(config['data']['jcasc.yaml'])
            except Exception as e:
                print(f"❌ Error parsing embedded JCasC: {e}")
                return False
        else:
            print(f"⚠️  ConfigMap doesn't contain jcasc.yaml data")
            return True

    # Validate structure
    all_passed = True
    all_passed &= check_required_sections(config, file_path)
    all_passed &= check_kubernetes_cloud(config, file_path)
    all_passed &= check_environment_variables(content, file_path)
    all_passed &= check_no_hardcoded_credentials(content, file_path)

    return all_passed


def main():
    """Main validation function."""
    # Find all JCasC-related files
    base_path = Path(__file__).parent.parent
    jcasc_files = [
        base_path / 'platform/apps/jenkins/jcasc.yaml',
        base_path / 'platform/apps/jenkins/jenkins-casc-configmap.yaml',
    ]

    print(f"\n{'='*70}")
    print("Jenkins Configuration as Code (JCasC) Validation")
    print(f"{'='*70}")

    all_passed = True
    for file_path in jcasc_files:
        if file_path.exists():
            passed = validate_jcasc_file(file_path)
            all_passed &= passed
        else:
            print(f"⚠️  File not found: {file_path}")

    print(f"\n{'='*70}")
    if all_passed:
        print("✅ All JCasC validations PASSED")
        print(f"{'='*70}\n")
        return 0
    else:
        print("❌ Some JCasC validations FAILED")
        print(f"{'='*70}\n")
        return 1


if __name__ == '__main__':
    sys.exit(main())
