variable "project_name" {
    description = "Name of the Project"
    type        = string
}

variable "region" {
    description = "AWS Region"
    type        = string
}

variable "cluster_name" {
    description = "Name of the cluster"
    type        = string
}

variable "namespace_name" {
    description = "Service Connection Cloudmap Namespace"
    type        = string
}

variable "vpc_id" {
    description = "Vpc id for the ECS Cluster"
    type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS Auto Scaling Group"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "Security Group ID for ECS EC2 instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the ECS EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for ECS EC2"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of ECS EC2 instances"
  type        = number
}

variable "min_size" {
  description = "Minimum number of ECS EC2 instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of ECS EC2 instances"
  type        = number
}
