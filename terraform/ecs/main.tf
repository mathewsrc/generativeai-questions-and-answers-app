resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.ecs_cluster_name
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = var.ecs_task_family_name

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.container_name}",
      "image": "${var.ecr_repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000
        }
      ]
    }
  ]
  DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = var.memory  # Specify the memory the container requires
  cpu                      = var.cpu     # Specify the CPU the container requires
  execution_role_arn       = var.ecs_task_execution_role_arn

  tags = {
    Environment = var.environment
    Application = var.name
    FamilyName  = var.ecs_task_family_name
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # Number of containers 

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = 8000
  }

  network_configuration {
    subnets = var.subnets
    assign_public_ip = true
    security_groups = var.ecs_service_security_groups_id
  }

  tags = {
    Environment = var.environment
    Application = var.name
    Name        = var.ecs_service_name
  }
}




