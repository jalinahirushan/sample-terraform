data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${local.name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "${local.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "database_secret_access" {
  statement {
    sid       = "ReadDatabaseCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.orders.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "database_secret_access" {
  name   = "database-secret-access"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.database_secret_access.json
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.environment == "production" ? 90 : 14
}

resource "aws_ecs_cluster" "application" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "application" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "application"
      image     = var.container_image
      essential = true
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "DATABASE_HOST", value = aws_db_instance.orders.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.orders.port) },
        { name = "DATABASE_SECRET_ARN", value = aws_db_instance.orders.master_user_secret[0].secret_arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "application"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "application" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.application.id
  task_definition = aws_ecs_task_definition.application.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  network_configuration {
    assign_public_ip = false
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.application.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.application.arn
    container_name   = "application"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}
