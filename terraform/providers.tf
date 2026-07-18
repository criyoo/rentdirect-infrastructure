# Environment Accounts (dev/Prod) / eu-west-1 region
provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.assume_role}"
  }

  default_tags {
    tags = local.common_tags
  }
}


# Environment Accounts (dev/Prod) / us-east-1 region
provider "aws" {
  alias  = "acm"
  region = var.acm_region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.assume_role}"
  }

  default_tags {
    tags = local.common_tags
  }
}

# Root Account / eu-west-1 region
provider "aws" {
  alias               = "root"
  region              = var.region
  allowed_account_ids = [var.root_account_id]

  default_tags {
    tags = merge(local.common_tags, {
      Environment = "root"
    })
  }
}
