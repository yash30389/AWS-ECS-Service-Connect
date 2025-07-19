# AWS-ECS-Service-Connect

# AWS ECS Service Connect - Multi-Container EC2 Setup

This Terraform project provisions an AWS ECS cluster on EC2 instances, running multiple containers that communicate securely using Service Connect and AWS Cloud Map private DNS namespaces.

## Architecture

- **VPC**: Custom VPC with public and private subnets.
- **EC2 Instances**: ECS cluster uses EC2 launch type, managed by an Auto Scaling Group.
- **Containers**: Multiple containers (`hello-1`, `hello-2`) run on the same EC2 instance.
- **Service Connect**: Enables private communication between containers using Cloud Map namespaces.
- **Load Balancer**: Application Load Balancer (ALB) routes external traffic to containers.

## Features

- **Private Channel Communication**: Containers communicate via Service Connect and Cloud Map, isolated from public internet.
- **Auto Scaling**: EC2 instances scale based on configuration.
- **Secure Access**: Security groups restrict access; ALB only exposes necessary ports.
- **Automated Key Management**: SSH key pair generated for EC2 access.

## Usage

1. **Configure Variables**  
   Edit [`variables.tf`](variables.tf) to set AWS credentials, region, project name, and subnet CIDRs.

2. **Initialize Terraform**
   ```sh
   terraform init