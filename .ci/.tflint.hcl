tflint {
  required_version  = ">= 0.50"
}

config {
    format          = "json"
    force           = true
    varfile         = [ ".ci/tests/idengr.tfvars" ]
}

plugin "aws" {
    enabled         = true
    version         = "0.32.0"
    source          = "github.com/terraform-linters/tflint-ruleset-aws"
}