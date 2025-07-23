resource "aws_ecs_service" "provindicators_api_service" {
  name            = "provindicators-api-service"
  cluster         = aws_ecs_cluster.provindicators_cluster.id
  task_definition = aws_ecs_task_definition.provindicators_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "LATEST"


  network_configuration {
    subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
}

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "provincial-indicators-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http_listener]
}
