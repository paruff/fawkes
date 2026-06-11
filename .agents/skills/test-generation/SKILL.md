---
name: test-generation
description: "TDD patterns and language-specific test examples for TypeScript/Jest, Python/pytest, and Go. Use when writing tests, increasing coverage, or implementing test-driven development."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Test Generation

> **Load trigger:** `"load test-generation skill"`
> **DORA:** Cap 5 (Small Batches / Shift Left on Quality)
> **Token cost:** Low

## TDD Pattern — Language Agnostic

### Commit Sequence (required order)

```
1. test: add failing tests for [feature]      ← CI fails here intentionally
2. feat: implement [feature] to pass tests
3. refactor: clean up [feature] if needed
```

## TypeScript/Jest Pattern

```typescript
// tests/services/auth.test.ts
import { signIn } from "../src/services/auth";
import { mockFirebaseAuth } from "./mocks/firebase";

describe("signIn", () => {
  it("returns user object on valid credentials", async () => {
    mockFirebaseAuth.mockResolvedValueOnce({
      uid: "user-123",
      email: "test@test.com",
    });
    const result = await signIn("test@test.com", "valid-password");
    expect(result.uid).toBe("user-123");
  });

  it("throws AuthError when credentials are invalid", async () => {
    mockFirebaseAuth.mockRejectedValueOnce(new Error("auth/wrong-password"));
    await expect(signIn("test@test.com", "wrong")).rejects.toThrow(
      "auth/wrong-password",
    );
  });

  it("throws AuthError when email is malformed", async () => {
    await expect(signIn("not-an-email", "password")).rejects.toThrow();
  });
});
```

## Python/pytest Pattern

```python
# tests/test_auth.py
import pytest
from unittest.mock import patch, MagicMock
from src.services.auth import sign_in, AuthError

def test_sign_in_returns_user_on_valid_credentials():
    with patch('src.services.auth.firebase_auth') as mock_auth:
        mock_auth.sign_in_with_password.return_value = {'uid': 'user-123'}
        result = sign_in('test@test.com', 'valid-password')
        assert result['uid'] == 'user-123'

def test_sign_in_raises_on_invalid_credentials():
    with patch('src.services.auth.firebase_auth') as mock_auth:
        mock_auth.sign_in_with_password.side_effect = Exception('INVALID_PASSWORD')
        with pytest.raises(AuthError):
            sign_in('test@test.com', 'wrong')
```

## Go Pattern

```go
// services/auth_test.go
package services

import (
    "testing"
    "errors"
)

func TestSignIn_ValidCredentials_ReturnsUser(t *testing.T) {
    mockAuth := &MockAuthProvider{
        SignInFunc: func(email, password string) (*User, error) {
            return &User{UID: "user-123"}, nil
        },
    }
    svc := NewAuthService(mockAuth)
    user, err := svc.SignIn("test@test.com", "valid-password")
    if err != nil { t.Fatalf("unexpected error: %v", err) }
    if user.UID != "user-123" { t.Errorf("expected user-123, got %s", user.UID) }
}
```

## Coverage Gap Triage Order

1. Uncovered error paths (highest value — crashes and data loss live here)
2. Uncovered branch conditions (if/else, switch cases)
3. Uncovered integration boundaries (service calls, DB calls)
4. Happy path gaps (lowest marginal value if 1–3 are covered)

## Mock Boundary Rule

Mock at the I/O boundary only:

- ✅ Mock HTTP client, database driver, filesystem, external SDK
- ❌ Mock internal service functions (tests implementation, not behavior)
- ❌ Mock the thing you are testing
