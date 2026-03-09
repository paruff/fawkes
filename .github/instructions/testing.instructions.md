---
name: Testing Instructions
description: Applied automatically when working in tests/
applyTo: "tests/**,services/**/*_test.go,**/*.test.py,**/*_test.go"
---

# Testing Instructions — Fawkes

## Core Rule: Test First, Always

Write the failing test. Commit it (RED). Then implement (GREEN).

Never delete a failing test — fix the code instead.

## Test Layers

| Layer | Location | Tool | When It Runs |
|---|---|---|---|
| Go unit | `services/{name}/*_test.go` | `go test` | Every PR |
| Python unit | `tests/unit/` | `pytest` | Every PR |
| Integration | `tests/integration/` | `pytest` | Every PR |
| BDD | `tests/bdd/` | `pytest-bdd` | Every PR |
| E2E / Platform | `tests/e2e/` | gated | Manual / scheduled |

## Go Test Pattern (Table-Driven)

```go
func TestDORALeadTime(t *testing.T) {
    tests := []struct {
        name    string
        commit  time.Time
        deploy  time.Time
        want    time.Duration
        wantErr bool
    }{
        {
            name:   "typical PR — 2 hours",
            commit: time.Date(2026, 3, 1, 9, 0, 0, 0, time.UTC),
            deploy: time.Date(2026, 3, 1, 11, 0, 0, 0, time.UTC),
            want:   2 * time.Hour,
        },
        {
            name:    "deploy before commit — error",
            commit:  time.Date(2026, 3, 1, 11, 0, 0, 0, time.UTC),
            deploy:  time.Date(2026, 3, 1, 9, 0, 0, 0, time.UTC),
            wantErr: true,
        },
        {
            name:   "same timestamp — zero lead time",
            commit: time.Date(2026, 3, 1, 9, 0, 0, 0, time.UTC),
            deploy: time.Date(2026, 3, 1, 9, 0, 0, 0, time.UTC),
            want:   0,
        },
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateLeadTime(tt.commit, tt.deploy)
            if (err != nil) != tt.wantErr {
                t.Errorf("wantErr %v, got %v", tt.wantErr, err)
            }
            if got != tt.want {
                t.Errorf("want %v, got %v", tt.want, got)
            }
        })
    }
}
```

## Python Test Pattern

```python
import pytest
from decimal import Decimal

@pytest.mark.parametrize("deployment_freq, lead_time, expected_tier", [
    (10.0, 0.5, "elite"),
    (1.0, 24.0, "high"),
    (0.1, 168.0, "medium"),
    (0.01, 720.0, "low"),
])
def test_dora_performance_tier(deployment_freq, lead_time, expected_tier):
    result = classify_dora_tier(deployment_freq, lead_time)
    assert result == expected_tier

def test_dora_tier_invalid_negative_freq():
    with pytest.raises(ValueError, match="deployment_freq must be > 0"):
        classify_dora_tier(-1.0, 24.0)
```

## BDD Feature File Pattern

```gherkin
Feature: DORA Metrics Dashboard
  As a platform engineer
  I want to see my team's DORA metrics
  So that I can track progress toward elite performance

  Scenario: View deployment frequency
    Given the platform has recorded 15 deployments in the last 7 days
    When I view the DORA metrics dashboard
    Then I see deployment frequency of 2.14 per day
    And the tier is shown as "Elite"

  Scenario: No deployments recorded
    Given the platform has no deployment records
    When I view the DORA metrics dashboard
    Then I see deployment frequency of 0
    And a prompt to configure the metrics collector
```

## Every Test Must Have

1. **Happy path** — expected inputs produce expected output
2. **Invalid input** — bad data handled gracefully with clear error
3. **Edge case** — zero, empty, negative, maximum

## What Tests Must Never Do

- Call live cloud APIs or live Kubernetes — use mocks/fakes
- Depend on test execution order — each test fully self-contained
- Use `time.Sleep` for synchronisation — use channels or retries with timeout
- Skip with `t.Skip()` or `pytest.skip()` without a tracking issue comment
