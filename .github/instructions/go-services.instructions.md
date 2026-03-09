---
name: Go Service Instructions
description: Applied automatically when working in services/
applyTo: "services/**/*.go"
---

# Go Service Instructions — Fawkes

## Read First
- `AGENTS.md` → Language & Layer Map
- `docs/ARCHITECTURE.md` → service boundary rules
- `docs/API_SURFACE.md` → existing service interfaces (don't duplicate)

## Fawkes Go Standards

### Package Structure
```
services/{service-name}/
  cmd/          → main.go entrypoints only — no business logic
  internal/     → private packages, business logic
  pkg/          → public, importable packages
  {name}_test.go → table-driven tests alongside source
```

### Error Handling
```go
// ✅ Correct
if err != nil {
    return fmt.Errorf("createUser: %w", err)
}

// ❌ Never
if err != nil {
    return err  // no context
}

// ❌ Never
_ = doSomething()  // discarded error
```

### All Exported Functions Need Godoc
```go
// CreateUser provisions a new platform user and assigns default RBAC roles.
// It returns ErrUserExists if the username is already taken.
func CreateUser(ctx context.Context, req CreateUserRequest) (*User, error) {
```

### No Global Mutable State
```go
// ❌ Never
var globalConfig *Config

// ✅ Pass dependencies explicitly
func NewServer(cfg *Config, db *DB) *Server {
```

### Test Pattern
```go
func TestCalculateLeadTime(t *testing.T) {
    tests := []struct {
        name    string
        input   LeadTimeInput
        want    time.Duration
        wantErr bool
    }{
        {"happy path", LeadTimeInput{...}, 2 * time.Hour, false},
        {"zero commit time", LeadTimeInput{CommitTime: time.Time{}}, 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // ...
        })
    }
}
```

## Linters That Must Pass

Run before every commit:
```bash
gofmt -l .           # no output = pass
golangci-lint run    # uses .golangci.yml config
go test ./...        # all tests green
```

## What Requires Human Approval
- New external Go dependencies (`go get`)
- New inter-service gRPC/HTTP contracts
- Changes to authentication or RBAC logic
