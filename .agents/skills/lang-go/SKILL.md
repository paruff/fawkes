---
name: lang-go
description: "Go toolchain: golangci-lint, go vet, go test, go mod. CI gate commands, file layout, interface patterns. Use when working on a Go project."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Language — Go

> **Load trigger:** `"load lang-go skill"`
> **Stack:** Go 1.22+, golangci-lint, go vet, go test, go test -cover, go mod
> **Token cost:** Low

## Toolchain Reference

| Gate            | Tool          | Command                                           | Config file            |
| --------------- | ------------- | ------------------------------------------------- | ---------------------- |
| Lint            | golangci-lint | `golangci-lint run ./...`                         | `.golangci.yml`        |
| Vet             | go vet        | `go vet ./...`                                    | none                   |
| Test            | go test       | `go test ./...`                                   | none                   |
| Coverage        | go test       | `go test -cover -coverprofile=coverage.out ./...` | none                   |
| Coverage report | go tool       | `go tool cover -func=coverage.out`                | none                   |
| Preflight       | shell         | `./scripts/preflight.sh`                          | `scripts/preflight.sh` |

## File Layout Convention

```
cmd/
  [service-name]/
    main.go             ← entry point only; no business logic
internal/
  services/             ← business logic
  handlers/             ← HTTP handlers (net/http or chi/gin)
  models/               ← data types and interfaces
  utils/                ← pure utility functions
pkg/
  [shared-packages]/    ← packages safe to import externally
go.mod
go.sum
```

## CI Gate Commands (ci-quality.yml)

```yaml
- name: Set up Go
  uses: actions/setup-go@v5
  with:
    go-version: "1.22"

- name: Lint
  uses: golangci/golangci-lint-action@v6
  with:
    version: latest

- name: Vet
  run: go vet ./...

- name: Test with coverage
  run: |
    go test -coverprofile=coverage.out ./...
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage ${COVERAGE}% below 80% threshold"
      exit 1
    fi
```

## Go Standards

- Errors are returned, not panicked (except in `main()` or init)
- Interfaces defined at the point of use (consumer), not at definition
- Context propagated as first argument in every function that does I/O
- No global mutable state in packages
- Table-driven tests for functions with multiple input/output cases

## Interface Pattern for Testability

```go
// Define interface in the consuming package
type AuthProvider interface {
    SignIn(ctx context.Context, email, password string) (*User, error)
}

// Implementation satisfies it implicitly
type FirebaseAuthProvider struct { ... }
func (f *FirebaseAuthProvider) SignIn(...) (*User, error) { ... }
```

## .golangci.yml Minimum Config (from paruff/fawkes)

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
run:
  timeout: 5m
```

Note: paruff/fawkes has a `.golangci.yml` — use it as the source of truth for
any project integrating with that repo.

## OTEL SDK (for obs-agent)

```bash
go get go.opentelemetry.io/otel \
       go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp \
       go.opentelemetry.io/otel/sdk/trace
```

Init pattern: call `initTracer()` at start of `main()`, defer `shutdown()`.
Read `OTEL_SERVICE_NAME` and `OTEL_EXPORTER_OTLP_ENDPOINT` from `os.Getenv`.
