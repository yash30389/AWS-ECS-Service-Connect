output "ecs_vpc_id" {
  description = "ID of the Jenkins VPC"
  value       = module.vpc.vpc_id
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value = module.ecs.ecs_cluster_id
}

output "ecs_cluster_namespace" {
  description = "Namespace for the ECS cluster in Cloud Map"
  value = module.ecs.cloudmap_namespace_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value = module.ecs.ecs_service_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value = module.ecs.ecs_cluster_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value = module.ecs.ecs_task_definition_arn
}
