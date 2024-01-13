resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

data "aws_iam_policy_document" "ecs_task_exec_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = var.ecs_task_family_name

  container_definitions = <<DEFINITION
  [
    {
      "name": ${var.container_name},
      "image": "${aws_ecr_repository.bedrock.repository_url}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_security_group" "ecs_service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.ecs_load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = aws_ecs_task_definition.ecs_task_definition.family
    container_port   = 8000
  }

  network_configuration {
    subnets = [
      "${aws_default_subnet.default_subnet_a.id}",
      "${aws_default_subnet.default_subnet_b.id}"
    ]
    assign_public_ip = true
    security_groups = [
      "${aws_security_group.ecs_service_security_group.id}"
    ]
  }
}




