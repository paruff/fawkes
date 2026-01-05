# TFLint configuration for GCP modules
# GCP VPC/network resources don't support labels, but we keep the 'tags' variable
# for consistency with base modules across AWS/Azure/GCP

rule "terraform_unused_declarations" {
  enabled = false
}
