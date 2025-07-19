# AWS-ECS-Service-Connect

# AWS ECS Service Connect Example

This Terraform project demonstrates how to set up **AWS ECS Service Connect** for secure, private communication between ECS services running on EC2 instances. The architecture uses AWS Cloud Map private DNS namespaces to enable service discovery and internal connectivity, ensuring that traffic between services remains within your VPC.

## Features

- **VPC & Subnets:** Creates a dedicated VPC with public and private subnets.
- **ECS Cluster:** Deploys an ECS cluster with EC2 launch type.
- **Service Connect:** Enables AWS ECS Service Connect for seamless, private service-to-service communication using Cloud Map private DNS.
- **EC2 Instances:** Launches EC2 instances managed by Auto Scaling Groups as ECS cluster members.
- **IAM Roles:** Configures necessary IAM roles for ECS tasks and EC2 instances.
- **Security Groups:** Restricts access to only required ports and enables internal traffic between services.
- **Application Load Balancer:** Provides external access to services if needed.
- **Autoscaling:** Implements autoscaling policies for ECS services based on CPU and memory utilization.

## How It Works

- Each ECS service registers itself in a private DNS namespace using AWS Cloud Map.
- Services communicate with each other using private DNS names (e.g., `hello1`, `hello2`) within the VPC.
- Service Connect ensures traffic between services is routed privately, without exposing endpoints to the public internet.

## Usage

1. **Configure Variables:** Edit [`variables.tf`](variables.tf) to set your AWS credentials, region, project name, and desired cluster configuration.
2. **Initialize Terraform:**
   ```sh
   terraform init
   ```
3. **Apply the Configuration:**
   ```sh
   terraform apply
   ```
4. **Access Services:** Use the private DNS names defined in Service Connect (`hello1`, `hello2`) for internal communication between ECS tasks.

## File Structure

- [`main.tf`](main.tf): Main Terraform configuration, including provider, VPC, ECS cluster, and modules.
- [`module/ecs/main.tf`](module/ecs/main.tf): ECS cluster, Service Connect, EC2 launch templates, services, and load balancer resources.
- [`module/vpc/main.tf`](module/vpc/main.tf): VPC and subnet resources.
- [`variables.tf`](variables.tf): Input variables for customization.
- [`outputs.tf`](outputs.tf): Useful outputs such as VPC ID, ECS cluster ID, and ALB DNS name.

## Architecture Diagram

```
[ALB] <---> [ECS Service: hello2] <--private DNS--> [ECS Service: hello1]
         |                                    |
      [EC2 Instance] <------VPC------> [EC2 Instance]
```

## Notes

- All inter-service traffic is routed privately within the VPC using Service Connect and Cloud Map.
- No public IPs are required for service-to-service communication.
- You can extend this setup to add more services or customize DNS names as needed.

---

**Author:** Yash  
**Purpose:** Demonstrate AWS ECS Service Connect for private EC2-based service communication using Terraform.
