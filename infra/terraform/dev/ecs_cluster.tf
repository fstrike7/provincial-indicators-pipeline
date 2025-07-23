resource "aws_ecs_cluster" "provindicators_cluster" {
  name = "provincial-indicators-ecs-dev"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "provincial-indicators-ecs-dev"
  }
}

# Rol para que ECS pueda usar imágenes de Docker y escribir logs en CloudWatch
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Política administrada de ECS para el rol
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
