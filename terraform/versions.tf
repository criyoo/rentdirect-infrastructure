terraform {
  required_version = "~> 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.43"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "s3" {
    bucket               = "rentdirect-statefile"
    key                  = "rentdirect.tfstate"
    region               = "eu-west-1"
    encrypt              = true
    use_lockfile         = true
    workspace_key_prefix = "envs"
  }
}
