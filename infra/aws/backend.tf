# =============================================================================
# Remote State Backend — AWS S3 + DynamoDB
# =============================================================================
# Usage:
#   terraform init -backend-config="bucket=fawkes-terraform-state" \
#                  -backend-config="key=aws/terraform.tfstate" \
#                  -backend-config="region=us-east-2" \
#                  -backend-config="dynamodb_table=fawkes-terraform-locks"
#
# Or use a backend.hcl file:
#   terraform init -backend-config=backend.hcl
# =============================================================================

terraform {
  backend "s3" {
    #_bucket         = "fawkes-terraform-state"
    #key             = "aws/terraform.tfstate"
    #region          = "us-east-2"
    #dynamodb_table  = "fawkes-terraform-locks"
    #encrypt         = true

    # Uncomment above and provide values via -backend-config or backend.hcl
    # Default: local state (temporary — migrate to S3 before team use)
  }
}
