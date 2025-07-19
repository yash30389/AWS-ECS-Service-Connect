variable "access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for ECS EC2"
  type        = string
  default     = "t2.micro"
}

variable "desired_capacity" {
  description = "Desired number of instances in the ECS cluster"
  type        = number
  default = 1
}

variable "min_size" {
  description = "Minimum number of instances in the ECS cluster"
  type        = number
  default = 0
}

variable "max_size" {
  description = "Maximum number of instances in the ECS cluster"
  type        = number
  default = 2
}
