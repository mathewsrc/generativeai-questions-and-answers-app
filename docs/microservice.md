# Microservice with ECS, Docker and FastAPI

This project application employs the microservices architecture, featuring a Rest API developed with the FastAPI library. The application is containerized using Docker and deployed in the cloud through AWS ECS.

## ECR

Unlike Lambda functions, the ECS service is a Platform as a Service (PaaS) but can used as Serveless 
using the Fargate option, enabling the execution of containers housed in the Elastic Container Registry (ECR). 
ECR serves as a repository, facilitating the storage of both private and public container images. 

The `scan_on_push` option helps to identify software vulnerabilities in container images and the `image_tag_mutability` allow image tags from being overwritten.

Directory: `terraform/ecr`

```terraform
# Create an ECR repository
resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Environment = var.environment
    Application = var.application_name
    Name        = var.ecr_name
  }
}
```

### ECR Policy

Set of actions to create ECR repository

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": [
                "arn:aws:ecr:us-east-1:*:repository/*"
            ]
        },
        {
            "Sid": "Statement2",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

## Secrets Manager 

In contrast to Lambda functions, the ECS service lacks the Environment feature for securely storing sensitive information like API keys. An alternative approach involves leveraging the AWS Secrets Manager service to securely store such confidential data. 

The following code snippet shows two Terraform resources used to create Qdrant key-pair secrets:

Directory: `terraform/secrets_manager`

```terraform
resource "aws_secretsmanager_secret" "qdrant_url" {
  name                           = var.qdrant_url_key
  description                    = "Qdrant URL Key"
  recovery_window_in_days        = 0    # Force deletion without recovery
  force_overwrite_replica_secret = true # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant URL"
    Environment = var.environment
    Application = var.application_name
  }
}

# Create a secret for Qdrant API Key, so ECS can access it
resource "aws_secretsmanager_secret" "qdrant_api_key" {
  name                           = var.qdrant_api_key
  description                    = "Qdrant API Key"
  recovery_window_in_days        = 0    # Force deletion without recovery
  force_overwrite_replica_secret = true # Force overwrite a secret with the same name in the destination Region.
  tags = {
    Name        = "Qdrant API Key"
    Environment = var.environment
    Application = var.application_name
  }
}
```

### Secrets Manager policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Load Balancer

The Load Balancer is a service that helps to redirect the traffic to least used node to make sure load is always balanced between each container holding same service.

The `internal` option when set to True block the direct access to the services, as this project uses API Gateway
to access the service we can set it to True.

The `load_balancer_type` has three option application, gateway, or network.

Directory: `terraform/load_balancer`

```terraform
# Create a Network Load Balancer
resource "aws_lb" "lb" {
  name                       = var.nlb_name
  internal                   = true
  load_balancer_type         = "application"
  subnets                    = var.public_subnets
  security_groups            = var.security_group_ids
  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Name        = var.nlb_name
    Terraform   = "true"
    Application = var.application_name
  }
}
```

## Target group

The target group route requests to one or more registered targets - ECS, Lambda Functions, EC2 instances.

The `vpc_id` specify where the target group will be created.
The `protocol = HTTP` sets the protocol to use for routing traffic to the targets and `target_type = ip` sets the type of target that the target group routes traffic to in this case
the targets are specified by IP address. 
 
Directory: `terraform/load_balancer`

```terraform
# Create a target group
resource "aws_lb_target_group" "target_group" {
  depends_on  = [aws_lb.lb]
  name        = var.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
```

## Load balancer listener

The listener checks for connection requests from clients, using the protocol (HTTP) and port (80) and redirect traffic from the load balancer to the target group. 

The `type` option defines the type of routing action. The `forward` type routes requests to one or more target groups.

Directory: `terraform/load_balancer`

```terraform
# Redirect traffic from the Load Balancer to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
```
## ECS

The ECS Terraform script create three required resources: cluster, task definition, and service 

### Cluster

The cluster is a logical grouping of tasks or services. The cluster also contains the infrastructure capacity:
Amazon EC2 instances, AWS Fargate, and network (VPC and subnet). 

Directory: `terraform/ecs`

```terraform
# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  tags = {
    Environment = var.environment
    Name        = var.ecs_cluster_name
    Application = var.application_name
  }
}
```

### Task definition

The task definition defines containers configurations: ECR Docker image, runtime plataform (OS), ports, 
network mode, maximum memory, maximum CPU, as well as the specific CPU and memory resources allocated
to each task. Additionally, the task definition outlines the IAM role utilized by the tasks 
and the chosen launch type, which determines the underlying infrastructure hosting the tasks.

The following Terraform snippet is designed to fetch the latest Git commit hash, serving as a dynamic and version-specific tag for the container.

Directory: `terraform/ecs`

```terraform
# Get the latest git commit hash (feel free to add more variables)
data "external" "envs" {
  program = ["sh", "-c", <<-EOSCRIPT
    jq -n '{ "sha": $SHA }' \
      --arg SHA "$(git rev-parse HEAD)" \  # Call git rev-parse HEAD command
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
```

### Service

The following Terraform code snippet defines the ECS service using the task definition, the load balancer, and
the network configuration:

Directory: `terraform/ecs`

```terraform
# Create an ECS service
resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 2 # Number of containers 
  depends_on      = []

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.ecs_service_name
    container_port   = 80
  }

  network_configuration {
    subnets = var.private_subnets # Instance under this subnet can’t be accessed from the Internet directly
    #assign_public_ip = true
    security_groups = var.ecs_tasks_security_group_id
  }

  tags = {
    Environment = var.environment
    Application = var.application_name
    Name        = var.ecs_service_name
  }
}
```

## Policies

### ECS task execution role policy

The ECS tasks necessitate this role for the purpose of retrieving container images and seamlessly publishing container logs to Amazon CloudWatch on your behalf.

Directory: `terraform/ecs`

```terraform
# Generates an IAM policy document for the ECS task executor role
data "aws_iam_policy_document" "ecs_task_executor_policy" {
  statement {
    sid = 1
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
  statement {
    sid = 2
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}
```

### Tasks role policy

This role is employed to grant access to your services deployed in ECS containers, facilitating seamless communication with other AWS services. The following Terraform code snippet grant access to AWS Bedrock,
AWS S3, and AWS Secrets Mananger services.

Directory: `terraform/ecs`

```terraform
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid       = 1
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
  statement {
    sid       = 2
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", 
    "bedrock:ListFoundationModels", "bedrock:InvokeModelWithResponseStream"]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
  statement {
    sid       = 3
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::bedrock-qa-bucket-tf/*"]
  }
  statement {
    sid       = 4
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_manager_arns
  }
}
```

## Docker image

The following Docker image defines the container that will be running in ECS:

```terraform
FROM python:3.12-slim-bullseye

# Install curl and curl the poetry installer
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive && \
  apt install -y curl && \
  curl -sSL https://install.python-poetry.org | python

# Sets the PATH to get the poetry bin
ENV PATH="/root/.local/bin:${PATH}"

# Set the working directory
WORKDIR /code

# Copy the files to the working directory
COPY ./pyproject.toml /code/pyproject.toml
COPY ./poetry.lock /code/poetry.lock 
COPY ./README.md /code/README.md
COPY ./src/app /code/app

# Configure poetry to create virtualenvs inside the project
RUN poetry config virtualenvs.in-project true

# Install dependencies using poetry
RUN poetry install --no-root

# Defines the port that the application listens on
EXPOSE 80

# Run the application using unicorn on port 8000
CMD ["poetry", "run", "uvicorn", "--host", "0.0.0.0", "--port", "80", "app.main:app", "--reload"]
```


## Rest API

The following code snippet shows the two endpoints created with FastAPI library

Directory: `src/app`

```python
@app.get("/", response_class=HTMLResponse)
async def root():
    """
    Endpoint for handling GET requests at the root path ("/").
    Return a welcome message
    """
    ...
```

```python
@app.post("/ask")
async def question(body: Body):
    """
    Endpoint for handling POST requests at the "/ask" path.
    Receives a request body parameter named 'body' of type 'Body'.
    Return the model answer
    """    
    ...
```

```python
@app.get("/collectioninfo")
async def collection_info():
  """
  Endpoint for handling GET requests at the root path ("/collectioninfo")
  Returns Qdrant collection information
  """
  ...
```

### ECS policy

Set of actions to create ECS resources

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:DeleteSubnet",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:CreateVpc",
                "ec2:RunInstances",
                "ec2:ModifyVpcAttribute",
                "ec2:DeleteVpc",
                "ec2:CreateSubnet",
                "ec2:ModifySubnetAttribute",
                "ec2:CreateDefaultSubnet",
                "ec2:AssociateRouteTable",
                "ec2:CreateLocalGatewayRouteTable",
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable",
                "ec2:DeleteLocalGatewayRouteTable",
                "ec2:DisassociateRouteTable",
                "ec2:CreateInternetGateway",
                "ec2:DeleteInternetGateway",
                "ec2:AttachInternetGateway",
                "ec2:CreateEgressOnlyInternetGateway",
                "ec2:DeleteEgressOnlyInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:DeleteVpnConnectionRoute",
                "ec2:CreateVpnConnection",
                "ec2:CreateVpnConnectionRoute"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "arn:aws:ec2:us-east-1:*:security-group/*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": [
                "arn:aws:ec2:us-east-1:*:subnet/*",
                "arn:aws:ec2:us-east-1:*:vpc/*"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "ecs:DeregisterTaskDefinition",
                "ecs:RegisterTaskDefinition",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeClusters",
                "ecs:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateCluster",
                "ecs:UpdateClusterSettings",
                "ecs:DeleteCluster",
                "ecs:CreateCluster"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor5",
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:CreateService",
                "ecs:DeleteService",
                "ecs:DescribeServices",
                "ecs:ListServices",
                "ecs:ListServicesByNamespace"
            ],
            "Resource": "arn:aws:ecs:us-east-1:*:service/*/*"
        },
        {
            "Sid": "VisualEditor6",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeInstanceHealth"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor7",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:DeleteListener"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:us-east-1:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:us-east-1:*:loadbalancer/app/*/*",
                "arn:aws:elasticloadbalancing:us-east-1:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:us-east-1:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:us-east-1:*:listener/net/*/*/*"
            ]
        },
        {
            "Sid": "VisualEditor8",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups",
                "logs:FilterLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor11",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateDefaultVpc",
                "ec2:CreateDefaultSubnet"
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1:*:subnet/*",
                "arn:aws:ec2:us-east-1:*:vpc/*"
            ]
        }
    ]
}
```

## VPC Link

The VPC link facilitates the API Gateway's access to the Amazon ECS service running within the Amazon VPC. Subsequently, you establish an Rest or HTTP API that leverages the VPC link to establish a connection with the Amazon ECS service.

The `target_arns` argument receives a list of network load balancer arns in the VPC targeted by the VPC link. 

Directory: `terraform/api_gateway`

```terraform
# Create a VPC Link from the API Gateway to the Load Balancer
resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = var.vpc_link_name
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids
}
```

## API Gateway

The `aws_apigatewayv2_api` are used for creating and deploying HTTP APIs

Directory: `terraform/api_gateway`

```terraform
resource "aws_apigatewayv2_api" "example" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "HTTP API for Question and Answer App"
  version       = "1.0"

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
```

### Integration

The integration integrates the HTTP API to the the Load balancer. It also defines

the `integration_type` (AWS, AWS_PROXY, HTTP, HTTP_PROXY, and MOCK), the HTTP method, the URI,
and the connection type.

The `integration_type` argument expects the ARN from the Load balancer listener

The `HTTP_PROXY` type permit API Gateway passes the incoming request from the client to the HTTP endpoint and passes the outgoing response from the HTTP endpoint to the client. Setting the integration request or integration response is not required when utilizing the HTTP proxy type. More information: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-integration-types.html

Directory: `terraform/api_gateway`

```terraform
# Integration for POST /ask
resource "aws_apigatewayv2_integration" "ask_integration" {
  api_id               = aws_apigatewayv2_api.example.id
  integration_type     = "HTTP_PROXY"
  integration_uri      = var.lb_listener_arn
  integration_method   = "POST"
  connection_type      = "VPC_LINK"
  connection_id        = aws_apigatewayv2_vpc_link.vpc_link.id
  timeout_milliseconds = 30000 # 30 seconds
}
```

### Routes

The `aws_apigatewayv2_route` define the HTTP method and the backend endpoint `/ask` 

Directory: `terraform/api_gateway`

```terraform
resource "aws_apigatewayv2_route" "ask_route" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "POST /ask"
  target    = "integrations/${aws_apigatewayv2_integration.ask_integration.id}"
}
```

### CloudWatcher logs

This resource create a log group to store logs from API Gateway

Directory: `terraform/api_gateway`

```terraform
resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${var.application_name}/${var.api_name}"
  retention_in_days = 7 
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
```

### Stage

Each stage is a named reference to a deployment of the API and is made available for client applications to call.

Directory: `terraform/api_gateway`

```terraform
resource "aws_apigatewayv2_stage" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  description = "Stage for HTTP API"
  name        = "$default" # The $default stage is a special stage that's automatically associated with new deployments.
  auto_deploy = true       # Whether updates to an API automatically trigger a new deployment.

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format = jsonencode({
      requestId = "$context.requestId",
      ip        = "$context.identity.sourceIp",
      user      = "$context.identity.user",
      caller    = "$context.identity.caller",
      request   = "$context.requestTime",
      status    = "$context.status",
      response  = "$context.responseLength"
    })
  }
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
```

### API Gateway Usage Plan

An API Gateway Usage Plan define who can access deployed API stages and methods. A quota define the maximum number of requests that can be made in a given time period and in which time period the limit applies. Throttle settings can be configured at the API or API method level, determining the maximum rate limit over a customizable time frame, ranging from one to a few seconds. Throttling initiates when the target point is reached.

Directory: `terraform/api_gateway`

```terraform
# Create a API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name        = var.usage_plan_name
  description = "QA Usage Plan"

  quota_settings {
    limit  = var.quota_limit  # Maximum number of requests that can be made in a given time period.
    offset = var.quota_offset # Number of requests to subtract from the given limit.   
    period = var.period       # Time period in which the limit applies. Valid values are "DAY", "WEEK" or "MONTH".
  }

  throttle_settings {
    burst_limit = var.burst_limit # The maximum rate limit over a time ranging from one to a few seconds
    rate_limit  = var.rate_limit  # The API request steady-state rate limit.
  }

  tags = {
    Name        = var.usage_plan_name
    Environment = var.environment
    Application = var.application_name
  }
}
```

## Policy for API Gateway

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "apigateway:DELETE",
                "apigateway:PUT",
                "apigateway:PATCH",
                "apigateway:POST",
                "apigateway:GET"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/vpclinks",
                "arn:aws:apigateway:us-east-1::/vpclinks/*",
                "arn:aws:apigateway:us-east-1::/apis",
                "arn:aws:apigateway:us-east-1::/apis/*"
            ],
            "Condition": {
                "StringLikeIfExists": {
                    "apigateway:Request/apiName": "competition-notices*"
                }
            }
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "apigateway:DELETE",
                "apigateway:PUT",
                "apigateway:PATCH",
                "apigateway:POST",
                "apigateway:GET"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/account",
                "arn:aws:apigateway:us-east-1::/usageplans/*",
                "arn:aws:apigateway:us-east-1::/tags/*",
                "arn:aws:apigateway:us-east-1::/usageplans",
                "arn:aws:apigateway:us-east-1::/vpclinks",
                "arn:aws:apigateway:us-east-1::/vpclinks/*"
            ],
            "Condition": {
                "StringLikeIfExists": {
                    "apigateway:Request/apiName": "competition-notices*"
                }
            }
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "apigateway:DELETE",
                "apigateway:PUT",
                "apigateway:PATCH",
                "apigateway:POST",
                "apigateway:GET"
            ],
            "Resource": [
                "arn:aws:apigateway:us-east-1::/apis",
                "arn:aws:apigateway:us-east-1::/apis/*"
            ],
            "Condition": {
                "StringLikeIfExists": {
                    "apigateway:Request/apiName": "competition-notices*"
                }
            }
        },
        {
            "Sid": "VisualEditor7",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogStreams",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "arn:aws:logs:us-east-1:*:log-group:*"
        },
        {
            "Sid": "VisualEditor8",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:PutResourcePolicy",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:CreateLogGroup",
                "logs:DescribeResourcePolicies",
                "logs:GetLogDelivery",
                "logs:ListLogDeliveries",
                "logs:TagResource",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor9",
            "Effect": "Allow",
            "Action": "apigateway:TagResource",
            "Resource": [
                "arn:aws:apigateway:us-east-1::/account",
                "arn:aws:apigateway:us-east-1::/usageplans",
                "arn:aws:apigateway:us-east-1::/usageplans/*",
                "arn:aws:apigateway:us-east-1::/tags/*",
                "arn:aws:apigateway:us-east-1::/restapis",
                "arn:aws:apigateway:us-east-1::/vpclinks",
                "arn:aws:apigateway:us-east-1::/vpclinks/*",
                "arn:aws:apigateway:us-east-1::/apis/*",
                "arn:aws:apigateway:us-east-1::/apis"
            ],
            "Condition": {
                "StringLikeIfExists": {
                    "apigateway:Request/apiName": "competition-notices*"
                }
            }
        },
        {
            "Sid": "VisualEditor10",
            "Effect": "Allow",
            "Action": "apigateway:TagResource",
            "Resource": [
                "arn:aws:apigateway:us-east-1::/account",
                "arn:aws:apigateway:us-east-1::/usageplans/*",
                "arn:aws:apigateway:us-east-1::/tags/*",
                "arn:aws:apigateway:us-east-1::/usageplans",
                "arn:aws:apigateway:us-east-1::/vpclinks",
                "arn:aws:apigateway:us-east-1::/apis",
                "arn:aws:apigateway:us-east-1::/apis/*",
                "arn:aws:apigateway:us-east-1::/vpclinks/*"
            ],
            "Condition": {
                "StringLikeIfExists": {
                    "apigateway:Request/apiName": "competition-notices*"
                }
            }
        },
        {
            "Sid": "VisualEditor11",
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups",
                "logs:ListTagsLogGroup",
                "logs:DeleteLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:*:log-group:*"
            ]
        }
    ]
}
```