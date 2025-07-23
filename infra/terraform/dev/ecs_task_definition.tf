resource "aws_ecs_task_definition" "provindicators_api" {
  family                   = "provindicators-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "provincial-indicators-api"
      image     = "docker.io/fstrike7/provincial-indicators-pipeline-api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/provindicators-api"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/provindicators-api"
  retention_in_days = 7
}
