#!/usr/bin/env python3
"""
Run Great Expectations checkpoint and handle results.
"""
import sys
import os
import json
import argparse
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import great_expectations as gx
from great_expectations.checkpoint import Checkpoint


def run_checkpoint(checkpoint_name: str, gx_dir: str = "gx") -> dict:
    """
    Run a Great Expectations checkpoint.

    Args:
        checkpoint_name: Name of the checkpoint to run
        gx_dir: Path to Great Expectations directory

    Returns:
        Dict with validation results
    """
    # Get data context
    context = gx.get_context(context_root_dir=gx_dir)

    # Run checkpoint
    print(f"Running checkpoint: {checkpoint_name}")
    results = context.run_checkpoint(checkpoint_name=checkpoint_name)

    # Extract key information
    success = results.success
    statistics = results.statistics

    return {
        "success": success,
        "checkpoint_name": checkpoint_name,
        "statistics": {
            "evaluated_expectations": statistics.get("evaluated_expectations", 0),
            "successful_expectations": statistics.get("successful_expectations", 0),
            "unsuccessful_expectations": statistics.get("unsuccessful_expectations", 0),
            "success_percent": statistics.get("success_percent", 0)
        },
        "run_id": str(results.run_id) if hasattr(results, "run_id") else None
    }


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Run Great Expectations checkpoint")
    parser.add_argument("checkpoint", help="Checkpoint name to run")
    parser.add_argument("--gx-dir", default="gx", help="Great Expectations directory")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")

    args = parser.parse_args()

    try:
        results = run_checkpoint(args.checkpoint, args.gx_dir)

        if args.json:
            print(json.dumps(results, indent=2))
        else:
            print(f"\nCheckpoint: {results['checkpoint_name']}")
            print(f"Success: {results['success']}")
            print(f"\nStatistics:")
            print(f"  Evaluated: {results['statistics']['evaluated_expectations']}")
            print(f"  Successful: {results['statistics']['successful_expectations']}")
            print(f"  Failed: {results['statistics']['unsuccessful_expectations']}")
            print(f"  Success Rate: {results['statistics']['success_percent']:.1f}%")

        # Exit with non-zero code if validation failed
        sys.exit(0 if results['success'] else 1)

    except Exception as e:
        print(f"ERROR: Failed to run checkpoint: {e}", file=sys.stderr)
        if args.json:
            print(json.dumps({"success": False, "error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
