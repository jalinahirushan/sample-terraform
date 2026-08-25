provider "aws" {
  region = var.aws_region

  # CI uses placeholder credentials and an offline refresh-free plan. The hosted
  # worker supplies real short-lived STS credentials for isolated verification.
  skip_credentials_validation = var.ci_offline_plan
  skip_metadata_api_check     = true
  skip_requesting_account_id  = var.ci_offline_plan
  skip_region_validation      = var.ci_offline_plan

  default_tags {
    tags = local.common_tags
  }
}
