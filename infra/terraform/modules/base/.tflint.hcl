# TFLint configuration for base modules
# Base modules are reference-only templates that define variable patterns.
# They are not intended to be instantiated and don't contain resources.

# Disable unused variable check since base modules only define variables
rule "terraform_unused_declarations" {
  enabled = false
}

# Disable required version check since base modules are not complete modules
rule "terraform_required_version" {
  enabled = false
}

# Disable required providers check since base modules are not complete modules  
rule "terraform_required_providers" {
  enabled = false
}
