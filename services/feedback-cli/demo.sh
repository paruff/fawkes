#!/bin/bash

set -euo pipefail
# Demo script for Fawkes Feedback CLI

set -e

echo "========================================"
echo "Fawkes Feedback CLI - Feature Demo"
echo "========================================"
echo

# Clean up any previous demo data
rm -f ~/.fawkes-feedback/queue.json ~/.fawkes-feedback/config.yaml

echo "1. Check CLI version"
echo "-------------------"
fawkes-feedback --version
echo

echo "2. Initialize configuration"
echo "---------------------------"
echo "Using default configuration..."
fawkes-feedback config show
echo

echo "3. Submit feedback (offline - will queue)"
echo "----------------------------------------"
fawkes-feedback submit -r 5 -c "CLI" -m "Love the new feedback CLI tool!" -t feedback
echo

echo "4. Submit another feedback item"
echo "--------------------------------"
fawkes-feedback submit -r 4 -c "Documentation" -m "Docs are great but could use more examples"
echo

echo "5. Submit a bug report"
echo "----------------------"
fawkes-feedback submit -r 2 -c "Jenkins" -m "Build failing on main branch" -t bug_report
echo

echo "6. Check queue status"
echo "--------------------"
fawkes-feedback queue
echo

echo "7. Try to sync (will fail - no service running)"
echo "-----------------------------------------------"
fawkes-feedback sync || echo "  (Expected to fail - service not available)"
echo

echo "8. Show help for submit command"
echo "--------------------------------"
fawkes-feedback submit --help
echo

echo "========================================"
echo "Demo complete! 🎉"
echo "========================================"
echo
echo "The CLI tool successfully demonstrated:"
echo "  ✓ Version display"
echo "  ✓ Configuration management"
echo "  ✓ Feedback submission (3 items)"
echo "  ✓ Offline queue (automatic)"
echo "  ✓ Queue status display"
echo "  ✓ Sync attempt (graceful failure)"
echo "  ✓ Help system"
echo
echo "Queue file location: ~/.fawkes-feedback/queue.json"
echo "Config file location: ~/.fawkes-feedback/config.yaml"
echo
echo "To clean up demo data:"
echo "  rm -rf ~/.fawkes-feedback/"
