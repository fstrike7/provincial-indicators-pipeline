output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_sg.id
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "ecs_cluster_name" {
  description = "Nombre del ECS Cluster"
  value       = aws_ecs_cluster.provindicators_cluster.name
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.app_tg.arn
}
