output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_vpc_id" {
  description = "VPC ID where the ECS cluster is deployed"
  value = var.vpc_id
}

output "ecs_cluster_namespace" {
  description = "Name of the ECS Service Discovery namespace"
  value = aws_service_discovery_private_dns_namespace.service_ns.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "cloudmap_namespace_id" {
  description = "ID oF the ECS Service Discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.service_ns.id
}

output "cloudmap_namespace_arn" {
  description = "ARN of the ECS Service Discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.service_ns.arn
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.app_task.arn
}

output "ecs_task_family" {
  description = "Family name of the ECS Task Definition"
  value       = aws_ecs_task_definition.app_task.family
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.app_service.name
}

output "ecs_service_id" {
  description = "ID of the ECS Service"
  value       = aws_ecs_service.app_service.id
}

output "service_connect_namespace" {
  description = "Service discovery namespace name"
  value       = aws_service_discovery_private_dns_namespace.service_ns.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.ecs_alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.ecs_alb.arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.http_listener.arn
}

output "alb_target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.ecs_tg.arn
}

output "asg_name" {
  description = "Name of the ECS Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.ecs_lt.id
}
