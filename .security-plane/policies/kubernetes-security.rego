package main

# Policy: Block critical vulnerabilities
# Note: List of vulnerable base images should be maintained separately
# Consider using input.data.vulnerable_images for dynamic configuration
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    
    # Check if image uses specific vulnerable base images
    # This list should be regularly updated and ideally loaded from external data
    vulnerable_bases := ["alpine:3.0", "ubuntu:14.04", "node:10", "python:2.7"]
    base := container.image
    vulnerable_bases[_] == base
    
    msg := sprintf("Container '%s' uses vulnerable base image: %s. Please use a supported version.", [container.name, base])
}

# Policy: Require non-root user
deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    
    msg := "Containers must run as non-root user. Add securityContext.runAsNonRoot: true"
}

# Policy: Disallow privileged containers
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged
    
    msg := sprintf("Container '%s' is running in privileged mode, which is not allowed", [container.name])
}

# Policy: Require resource limits
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits
    
    msg := sprintf("Container '%s' must have resource limits defined", [container.name])
}

# Policy: Require resource requests
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests
    
    msg := sprintf("Container '%s' must have resource requests defined", [container.name])
}

# Policy: Disallow host network
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostNetwork
    
    msg := "Pods must not use host network"
}

# Policy: Disallow host PID
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostPID
    
    msg := "Pods must not use host PID namespace"
}

# Policy: Disallow host IPC
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostIPC
    
    msg := "Pods must not use host IPC namespace"
}

# Policy: Require liveness probe
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    
    msg := sprintf("Container '%s' should have a liveness probe defined", [container.name])
}

# Policy: Require readiness probe
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    
    msg := sprintf("Container '%s' should have a readiness probe defined", [container.name])
}

# Policy: Image must use specific tag (not latest)
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    
    msg := sprintf("Container '%s' uses ':latest' tag. Use specific version tags for reproducibility", [container.name])
}

# Policy: Require security context
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext
    
    msg := sprintf("Container '%s' must have a securityContext defined", [container.name])
}

# Policy: Drop all capabilities
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.capabilities.drop
    
    msg := sprintf("Container '%s' must drop all capabilities. Add securityContext.capabilities.drop: ['ALL']", [container.name])
}
