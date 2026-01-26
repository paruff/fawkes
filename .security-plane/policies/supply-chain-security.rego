package main

# Policy: Block images with CRITICAL vulnerabilities
deny[msg] {
    input.vulnerabilities[_].severity == "CRITICAL"
    count([v | input.vulnerabilities[v]; input.vulnerabilities[v].severity == "CRITICAL"]) > 0
    
    critical_count := count([v | input.vulnerabilities[v]; input.vulnerabilities[v].severity == "CRITICAL"])
    msg := sprintf("Image has %d CRITICAL vulnerabilities. These must be fixed before deployment", [critical_count])
}

# Policy: Warn on HIGH vulnerabilities
warn[msg] {
    input.vulnerabilities[_].severity == "HIGH"
    high_count := count([v | input.vulnerabilities[v]; input.vulnerabilities[v].severity == "HIGH"])
    high_count > 5
    
    msg := sprintf("Image has %d HIGH severity vulnerabilities. Consider fixing these issues", [high_count])
}

# Policy: Require SBOM presence
deny[msg] {
    not input.sbom
    not input.metadata.sbom_generated
    
    msg := "Image must have an SBOM (Software Bill of Materials) attached"
}

# Policy: Require image signature
deny[msg] {
    not input.signature
    not input.metadata.signed
    not input.metadata.cosign_verified
    
    msg := "Image must be signed with Cosign or equivalent signature mechanism"
}

# Policy: Block unsigned images in production
deny[msg] {
    input.environment == "production"
    not input.metadata.signed
    
    msg := "Production images must be cryptographically signed"
}

# Policy: Require base image from approved registries
deny[msg] {
    input.base_image
    approved_registries := ["ghcr.io", "docker.io/library", "gcr.io/distroless", "mcr.microsoft.com"]
    not registry_approved(input.base_image, approved_registries)
    
    msg := sprintf("Base image '%s' is not from an approved registry. Approved: %v", [input.base_image, approved_registries])
}

registry_approved(image, approved) {
    registry := split(image, "/")[0]
    approved[_] == registry
}

registry_approved(image, approved) {
    # Allow official Docker library images without registry prefix
    not contains(image, "/")
    startswith(image, "alpine")
}

registry_approved(image, approved) {
    not contains(image, "/")
    startswith(image, "ubuntu")
}

# Policy: Enforce image age limit
warn[msg] {
    input.metadata.created
    age_days := days_since(input.metadata.created)
    age_days > 90
    
    msg := sprintf("Image is %d days old. Consider updating to a more recent base image", [age_days])
}

days_since(timestamp) = days {
    # Simplified - in real implementation would parse timestamp
    days := 0
}

# Policy: Require vulnerability scan timestamp
warn[msg] {
    not input.metadata.last_scanned
    
    msg := "Image should have vulnerability scan metadata with timestamp"
}

# Policy: Block images with outdated packages
warn[msg] {
    input.packages[_].version
    input.packages[_].latest_version
    input.packages[p].version != input.packages[p].latest_version
    outdated_count := count([pkg | input.packages[pkg]; input.packages[pkg].version != input.packages[pkg].latest_version])
    outdated_count > 10
    
    msg := sprintf("Image has %d outdated packages. Consider updating dependencies", [outdated_count])
}
