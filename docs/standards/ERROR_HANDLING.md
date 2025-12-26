# Error Handling Standards

## Overview

This document defines the error handling standards for all shell scripts in the Fawkes platform.

## Core Requirements

### 1. Strict Error Mode

All shell scripts MUST start with:

```bash
set -euo pipefail
```

### 2. Use Error Handling Library

Source the centralized error handling library:

```bash
source "${SCRIPT_DIR}/lib/error_handling.sh"
```

## Exit Codes

- `0` - Success
- `1` - General error  
- `2` - Missing prerequisite
- `3` - Validation failed
- `4` - Network error
- `5` - Timeout
- `6` - User cancelled
- `7` - Configuration error
- `8` - Permission error

## See Also

- `/scripts/lib/error_handling.sh` - Implementation
- `/tests/unit/test_error_handling.sh` - Tests
