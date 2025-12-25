// ============================================================================
// FILE: platform/apps/unleash/examples/go-service.go
// PURPOSE: Example of integrating OpenFeature with Unleash in Go services
// ============================================================================

package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"

    "github.com/open-feature/go-sdk/openfeature"
    unleash "github.com/open-feature/go-sdk-contrib/providers/unleash/pkg"
)

// InitializeFeatureFlags initializes OpenFeature with Unleash provider
func InitializeFeatureFlags() error {
    unleashURL := os.Getenv("UNLEASH_API_URL")
    if unleashURL == "" {
        unleashURL = "https://unleash.fawkes.idp/api"
    }

    apiToken := os.Getenv("UNLEASH_API_TOKEN")
    if apiToken == "" {
        return fmt.Errorf("UNLEASH_API_TOKEN not set")
    }

    provider := unleash.NewProvider(
        unleash.WithURL(unleashURL),
        unleash.WithAppName("go-service"),
        unleash.WithAPIToken(apiToken),
        unleash.WithRefreshInterval(30 * time.Second),
    )

    openfeature.SetProvider(provider)
    return nil
}

// CheckFeatureEnabled checks if a feature flag is enabled
func CheckFeatureEnabled(ctx context.Context, featureName string, userID string) (bool, error) {
    client := openfeature.NewClient("my-app")

    evalCtx := openfeature.NewEvaluationContext(
        userID,
        map[string]interface{}{
            "environment": os.Getenv("ENVIRONMENT"),
            "team":        "platform",
        },
    )

    value, err := client.BooleanValue(ctx, featureName, false, evalCtx)
    if err != nil {
        return false, err
    }

    return value, nil
}

// Example: HTTP handler with feature flag
func HandleRequest(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    userID := r.Header.Get("X-User-ID")

    enabled, err := CheckFeatureEnabled(ctx, "new-feature", userID)
    if err != nil {
        log.Printf("Error checking feature flag: %v", err)
        http.Error(w, "Internal error", http.StatusInternalServerError)
        return
    }

    if enabled {
        w.Write([]byte("New feature enabled"))
    } else {
        w.Write([]byte("Feature not available"))
    }
}

func main() {
    if err := InitializeFeatureFlags(); err != nil {
        log.Fatalf("Failed to initialize feature flags: %v", err)
    }

    log.Println("Feature flags initialized")
}
