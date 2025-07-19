########### ECS Cluster ###############
#######################################

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

resource "aws_service_discovery_private_dns_namespace" "service_ns" {
  name        = var.namespace_name
  description = "Private namespace for ECS service discovery"
  vpc         = var.vpc_id

  tags = {
    Name = "${var.project_name}-namespace"
  }
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

################# ASG launch Template ####################
##########################################################

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

resource "aws_launch_template" "ecs_lt_hello2" {
  name_prefix   = "${var.cluster_name}-ecs-lt-hello2"
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
      Name = "${var.cluster_name}-ecs-ec2-hello2"
    }
  }
}

########### SSH key pair for ECS instances ###############
##########################################################

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

########### Capacity Provider Autoscaling Group ###############
###############################################################

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.cluster_name}-ecs-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 60

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
}

resource "aws_autoscaling_group" "ecs_asg_hello2" {
  name                      = "${var.cluster_name}-ecs-asg-hello2"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.ecs_lt_hello2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-ec2-hello2"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


########### capacity_providers ###############
##############################################


resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "${var.cluster_name}-ecs-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
      instance_warmup_period    = 60
    }
  }

  tags = {
    Name = "${var.cluster_name}-ecs-cp"
  }
}

resource "aws_ecs_capacity_provider" "ecs_cp_hello2" {
  name = "${var.cluster_name}-ecs-cp-hello2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg_hello2.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
      instance_warmup_period    = 60
    }
  }

  tags = {
    Name = "${var.cluster_name}-ecs-cp-hello2"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cp_attach" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_cp.name,
    aws_ecs_capacity_provider.ecs_cp_hello2.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp_hello2.name
    weight            = 1
    base              = 1
  }
}

########### ECS Task Definition ###############
###############################################

resource "aws_ecs_task_definition" "task_hello1" {
  family                   = "${var.project_name}-task-hello1"
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
        interval    = 20,
        timeout     = 6,
        retries     = 3,
        startPeriod = 30
      },
    }
  ])
}

resource "aws_ecs_task_definition" "task_hello2" {
  family                   = "${var.project_name}-task-hello2"
  requires_compatibilities = ["EC2"]
  network_mode            = "awsvpc"
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
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
        interval    = 20,
        timeout     = 6,
        retries     = 3,
        startPeriod = 30
      },
    }
  ])
}

########### ECS Service ###############
#######################################

resource "aws_ecs_service" "hello1_service" {
  name            = "${var.project_name}-hello1-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_hello1.arn
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
    namespace = aws_service_discovery_private_dns_namespace.service_ns.arn
    service {
      port_name = "hello-1-port"
      client_alias {
        port     = 3000
        dns_name = "hello1"
      }
    }
  }

  depends_on = [aws_lb_listener.http_listener]
}

resource "aws_ecs_service" "hello2_service" {
  name            = "${var.project_name}-hello2-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_hello2.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp_hello2.name
    weight            = 1
  }

  network_configuration {
    security_groups = [var.ec2_sg_id]
    subnets         = var.subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg_hello2.arn
    container_name   = "hello-2"
    container_port   = 5000
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.service_ns.arn
    service {
      port_name = "hello-2-port"
      client_alias {
        port     = 5000
        dns_name = "hello2"
      }
    }
  }

  depends_on = [aws_lb_listener.http_listener]
}

########### ECS LoadBalancer ###############
############################################

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

########### ECS LoadBalancer Target Group ###############
#########################################################

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "ecs_tg_hello1" {
  name        = "${var.cluster_name}-tg-hello1"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "ecs_tg_hello2" {
  name        = "${var.cluster_name}-tg-hello2"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "rule_hello2" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg_hello2.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_security_group_rule" "allow_alb_to_ecs_hello2" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = var.ec2_sg_id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to access ECS task on port 5000"
}

resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = var.ec2_sg_id
  source_security_group_id = var.ec2_sg_id
  description              = "Allow internal ECS traffic to backend"
}

########### ECS Service Autoscaling Target ###############
##########################################################
resource "aws_appautoscaling_target" "ecs_hello2_scaling_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.hello2_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "${var.project_name}-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_hello2_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_hello2_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_hello2_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "${var.project_name}-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_hello2_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_hello2_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_hello2_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 85.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

