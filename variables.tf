variable "project_name" {
  description = "Short project identifier used in AWS resource names."
  type        = string
  default     = "orders-api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "Project name must be 3-21 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Production enables additional guardrails."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "aws_region" {
  description = "AWS region for the stack."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR range allocated to the application VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "container_image" {
  description = "Immutable container image deployed by the ECS service."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:1.27-alpine"
}

variable "container_port" {
  description = "HTTP port exposed by the application container."
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Number of application tasks."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 2
    error_message = "At least two tasks are required for this highly available service."
  }
}

variable "database_instance_class" {
  description = "RDS instance class for the orders database."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_multi_az" {
  description = "Whether RDS maintains a synchronous standby in another AZ."
  type        = bool
  default     = true
}

variable "database_deletion_protection" {
  description = "Protect the production database from accidental deletion."
  type        = bool
  # DELIBERATE DEMO REGRESSION: production requires this to be true. Terraform
  # init and validate pass, while plan fails on aws_db_instance.orders.
  default = false
}

variable "ci_offline_plan" {
  description = "Skip AWS identity checks only for the refresh-free demo CI plan."
  type        = bool
  default     = false
}
