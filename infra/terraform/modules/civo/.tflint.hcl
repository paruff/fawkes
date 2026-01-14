plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "civo" {
  enabled = true
  version = "1.0.0"
  source  = "github.com/civo/tflint-ruleset-civo"
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}
