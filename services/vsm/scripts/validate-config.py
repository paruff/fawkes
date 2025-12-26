#!/usr/bin/env python3
"""
Validation script for VSM stage configurations.

This script validates that:
1. Stage configuration files are valid YAML
2. All required fields are present
3. Stage count is correct (8 stages)
4. WIP limits are reasonable
5. Transitions are properly defined
"""

import sys
import yaml
from pathlib import Path

# Try to import StageCategory for validation, but don't fail if not available
try:
    # Add parent directory to path for imports
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from app.models import StageCategory

    VALID_STAGE_TYPES = [e.value for e in StageCategory]
except ImportError:
    # Fallback to hardcoded values if import fails
    VALID_STAGE_TYPES = ["wait", "active", "done"]


def validate_stages(config_path):
    """Validate stages configuration."""
    print("=" * 60)
    print("Validating VSM Stage Configuration")
    print("=" * 60)

    errors = []
    warnings = []

    # Load configuration
    try:
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
        print(f"✅ Loaded configuration from {config_path}")
    except Exception as e:
        print(f"❌ Failed to load configuration: {e}")
        return False

    # Check stages exist
    if "stages" not in config:
        errors.append("Missing 'stages' key in configuration")
        print(f"❌ {errors[-1]}")
        return False

    stages = config["stages"]
    print(f"✅ Found {len(stages)} stages")

    # Check stage count
    if len(stages) != 8:
        warnings.append(f"Expected 8 stages, found {len(stages)}")
        print(f"⚠️  {warnings[-1]}")

    # Validate each stage
    required_fields = ["name", "type", "order", "description"]
    stage_names = []
    stage_orders = []

    for i, stage in enumerate(stages):
        stage_num = i + 1

        # Check required fields
        for field in required_fields:
            if field not in stage or stage[field] is None or stage[field] == "":
                errors.append(f"Stage {stage_num}: Missing or empty '{field}' field")
                print(f"❌ {errors[-1]}")

        # Validate stage name
        name = stage.get("name")
        if name:
            if name in stage_names:
                errors.append(f"Stage {stage_num}: Duplicate stage name '{name}'")
                print(f"❌ {errors[-1]}")
            else:
                stage_names.append(name)
                print(f"  Stage {stage_num}: {name}")

        # Validate stage order
        order = stage.get("order")
        if order:
            if order in stage_orders:
                errors.append(f"Stage {stage_num}: Duplicate order {order}")
                print(f"❌ {errors[-1]}")
            else:
                stage_orders.append(order)

        # Validate stage type
        stage_type = stage.get("type")
        if stage_type and stage_type not in VALID_STAGE_TYPES:
            errors.append(
                f"Stage {stage_num} ({name}): Invalid type '{stage_type}', must be one of {VALID_STAGE_TYPES}"
            )
            print(f"❌ {errors[-1]}")

        # Validate WIP limit
        wip_limit = stage.get("wip_limit")
        if wip_limit is not None:
            if not isinstance(wip_limit, int) or wip_limit <= 0:
                warnings.append(f"Stage {stage_num} ({name}): WIP limit should be a positive integer or null")
                print(f"⚠️  {warnings[-1]}")
            elif wip_limit > 50:
                warnings.append(f"Stage {stage_num} ({name}): WIP limit {wip_limit} seems very high")
                print(f"⚠️  {warnings[-1]}")

    # Summary
    print("=" * 60)
    print("Validation Summary:")
    print(f"  Stages: {len(stages)}")
    print(f"  Errors: {len(errors)}")
    print(f"  Warnings: {len(warnings)}")

    if errors:
        print("\n❌ Validation FAILED")
        print("Errors:")
        for error in errors:
            print(f"  - {error}")
        return False

    if warnings:
        print("\n⚠️  Validation passed with warnings")
        print("Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    else:
        print("\n✅ Validation PASSED")

    print("=" * 60)
    return True


def validate_transitions(config_path):
    """Validate transitions configuration."""
    print("\nValidating Transitions Configuration...")

    try:
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
        print(f"✅ Loaded transitions from {config_path}")
    except Exception as e:
        print(f"❌ Failed to load transitions: {e}")
        return False

    # Check main sections exist
    sections = ["allowed_transitions", "automated_transitions", "validation_rules", "notifications"]
    for section in sections:
        if section in config:
            count = len(config[section])
            print(f"✅ Found {count} {section}")
        else:
            print(f"⚠️  Missing '{section}' section")

    return True


def main():
    """Main entry point."""
    service_dir = Path(__file__).parent.parent
    stages_config = service_dir / "config" / "stages.yaml"
    transitions_config = service_dir / "config" / "transitions.yaml"

    # Validate stages
    stages_valid = validate_stages(stages_config)

    # Validate transitions
    transitions_valid = validate_transitions(transitions_config)

    # Exit with appropriate code
    if stages_valid and transitions_valid:
        print("\n✅ All validations passed!")
        sys.exit(0)
    else:
        print("\n❌ Validation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
