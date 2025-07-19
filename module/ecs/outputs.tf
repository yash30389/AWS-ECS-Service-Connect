output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.id
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
  value = aws_lb_listener.http_listener.arn
}

output "alb_target_group_arn_hello2" {
  value = aws_lb_target_group.ecs_tg_hello2.arn
}

