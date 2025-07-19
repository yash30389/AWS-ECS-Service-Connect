resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.cluster_name}"

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.service_ns.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}",
    Cluster = "${var.cluster_name}"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cp_attach" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
    base              = 1
  }
}

resource "aws_service_discovery_private_dns_namespace" "service_ns" {
  name        = var.namespace_name
  description = "Private namespace for ECS service discovery"
  vpc         = var.vpc_id

  tags = {
    Name = "${var.project_name}-namespace"
  }

  # depends_on = [aws_ecs_service.app_service]  // Ensure the namespace is deleted before the service
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })

  tags = {
    Name = "${var.cluster_name}-ecs-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.cluster_name}-ecs-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.ecs_key_pair.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.ec2_sg_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-ecs-ec2"
    }
  }
}

resource "tls_private_key" "ecs_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ecs_key_pair" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.ecs_key.public_key_openssh
}

resource "local_file" "private_key" {
  content          = tls_private_key.ecs_key.private_key_pem
  filename         = "${path.module}/${var.cluster_name}-key.pem"
  file_permission  = "0400"
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.cluster_name}-ecs-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-ec2"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # depends_on = [null_resource.scale_down_asg]    // For Resource deleteion
}

resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "${var.cluster_name}-ecs-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
      instance_warmup_period    = 300
    }
  }

  tags = {
    Name = "${var.cluster_name}-ecs-cp"
  }
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["EC2"]
  network_mode            = "awsvpc"
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "hello-1"
      image     = "yash30389/yash-app3:latest"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
          name          = "hello-1-port"
        }
      ],
      healthCheck = {
        command     = ["CMD", "true"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 10
      },
    },
    {
      name      = "hello-2"
      image     = "yash30389/yash-app5:latest"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
          name          = "hello-2-port"
        }
      ],
      healthCheck = {
        command     = ["CMD", "true"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 10
      },
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  # launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 1
  }

  network_configuration {
    security_groups = [var.ec2_sg_id] 
    subnets         = var.subnet_ids
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.service_ns.name

    service {
      port_name = "hello-1-port"
      discovery_name = "hello-1"
      client_alias {
        port     = 3000
        dns_name = "hello-1"
      }
    }

    service {
      port_name = "hello-2-port"
      discovery_name = "hello-2"
      client_alias {
        port     = 5000
        dns_name = "hello-2"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "hello-2"
    container_port   = 5000
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_lb_listener.http_listener,
    aws_lb_target_group.ecs_tg,
    aws_ecs_cluster_capacity_providers.ecs_cp_attach,
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }

  timeouts {
    delete = "20m"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "ecs_alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.cluster_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}


resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}


resource "aws_security_group_rule" "allow_alb_to_ecs" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = var.ec2_sg_id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to access ECS task on port 5000"
}
