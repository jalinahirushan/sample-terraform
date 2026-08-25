resource "aws_db_subnet_group" "orders" {
  name       = "${local.name_prefix}-database"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-database" }
}

resource "aws_db_instance" "orders" {
  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.database_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name                     = "orders"
  username                    = "orders_admin"
  manage_master_user_password = true
  port                        = 5432

  db_subnet_group_name   = aws_db_subnet_group.orders.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.database_multi_az

  backup_retention_period   = var.environment == "production" ? 14 : 3
  deletion_protection       = var.database_deletion_protection
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${local.name_prefix}-final" : null

  performance_insights_enabled = true
  auto_minor_version_upgrade   = true
  apply_immediately            = false

  lifecycle {
    precondition {
      condition     = var.environment != "production" || var.database_deletion_protection
      error_message = "Production databases must enable deletion protection."
    }

    precondition {
      condition     = var.environment != "production" || var.database_multi_az
      error_message = "Production databases must be deployed across multiple Availability Zones."
    }
  }

  tags = { Name = "${local.name_prefix}-postgres" }
}
