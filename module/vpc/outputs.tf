output "vpc_id" {
  description = "ID of the Jenkins VPC"
  value       = aws_vpc.ecs_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs in the VPC"
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs in the VPC"
  value = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}