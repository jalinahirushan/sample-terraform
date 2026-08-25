locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]

  public_subnet_cidrs  = ["10.42.0.0/24", "10.42.1.0/24"]
  private_subnet_cidrs = ["10.42.10.0/24", "10.42.11.0/24"]

  common_tags = {
    Application = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "sample-terraform"
  }
}
