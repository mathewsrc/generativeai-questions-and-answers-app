# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the current AWS region
data "aws_region" "current" {}

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  tags = {
    Environment = var.environment
    Name        = var.ecs_cluster_name
    Application = var.application_name
  }
}


# Get the Qdrant URL, API key and Git latest commit hash from the environment
data "external" "envs" {
  program = ["bash", "-c", <<-EOSCRIPT
    : "$${QDRANT_URL:?Missing environment variable QDRANT_URL}"
    : "$${QDRANT_API_KEY:?Missing environment variable QDRANT_API_KEY}"
    jq --arg QDRANT_URL "$(printenv QDRANT_URL)" \
       --arg QDRANT_API_KEY "$(printenv QDRANT_API_KEY)" \
       --arg SHA "$(git rev-parse HEAD)" \
       -n '{ "qdrant_url": $QDRANT_URL, 
             "qdrant_api_key": $QDRANT_API_KEY,
             "sha": $SHA}'
  EOSCRIPT
  ]
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {

  #container_definitions = file("../.aws/task-definition.json")
  container_definitions = templatefile("${path.module}/../../.aws/task-definition.json",
    { tag             = data.external.envs.result.sha,
      ecr             = var.ecr_repository_url,
      service_name    = var.ecs_service_name,
      region          = var.region,
      logs_group_name = var.logs_group_name
  })

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  family                   = var.ecs_task_family_name
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = var.memory  # Specify the memory the container requires
  cpu                      = var.cpu     # Specify the CPU the container requires
  execution_role_arn       = aws_iam_role.ecs_task_executor_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = {
    Environment = var.environment
    FamilyName  = var.ecs_task_family_name
    Application = var.application_name
  }
}

# Create an ECS service
resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Number of containers 
  depends_on      = []

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.ecs_service_name
    container_port   = 80
  }

  network_configuration {
    subnets          = var.private_subnets # Instance under this subnet can’t be accessed from the Internet directly
    assign_public_ip = false
    security_groups  = var.ecs_tasks_security_group_id
  }


  tags = {
    Environment = var.environment
    Application = var.application_name
    Name        = var.ecs_service_name
  }
}




