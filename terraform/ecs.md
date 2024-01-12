resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = var.ecs_task_name

  container_definitions = <<DEFINITION
  [
    {
      "name": "my-container",
      "image": "${aws_ecr_repository.bedrock.repository_url}:latest",  
      "cpu": 256,
      "memory": 512,
      "essential": true
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 4         # Specify the memory the container requires
  cpu                      = 2           # Specify the CPU the container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}
