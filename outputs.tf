output "load_balancer_url" {
  description = "Public URL for the orders API load balancer."
  value       = "http://${aws_lb.application.dns_name}"
}

output "database_endpoint" {
  description = "Private PostgreSQL endpoint consumed by ECS tasks."
  value       = aws_db_instance.orders.endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster running the orders API."
  value       = aws_ecs_cluster.application.name
}

output "private_subnet_ids" {
  description = "Private subnets used by ECS and RDS."
  value       = aws_subnet.private[*].id
}
