# Microservice with ECS, Docker and FastAPI

This project application employs the microservices architecture, featuring a Rest API developed with the FastAPI library. The application is containerized using Docker and deployed in the cloud through AWS ECS.

## ECR

Unlike Lambda functions, the ECS service is a Platform as a Service (PaaS) but can used as Serveless 
using the Fargate option, enabling the execution of containers housed in the Elastic Container Registry (ECR). 
ECR serves as a repository, facilitating the storage of both private and public container images. 

The `scan_on_push` option helps to identify software vulnerabilities in container images and the `image_tag_mutability` allow image tags from being overwritten.

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

## Secrets Manager 

In contrast to Lambda functions, the ECS service lacks the Environment feature for securely storing sensitive information like API keys. An alternative approach involves leveraging the AWS Secrets Manager service to securely store such confidential data. 

The following code snippet shows two Terraform resources used to create Qdrant key-pair secrets:

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

## Load Balancer

The Load Balancer is a service that helps to redirect the traffic to least used node to make sure load is always balanced between each container holding same service.

The `internal` option when set to True block the direct access to the services, as this project uses API Gateway
to access the service we can set it to True.

The `load_balancer_type` has three option application, gateway, or network.

VPC link requires the `network` option or we get the following error:
`Error: creating API Gateway VPC Link (vpc-link): waiting for completion: FAILED: NLB ARN is malformed`. You can
check this link for more information: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-nlb-for-vpclink-using-console.html


```terraform
# Create a Network Load Balancer
resource "aws_lb" "lb" {
  name                       = var.nlb_name
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = var.public_subnets
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
The `protocop = TCP` sets the protocol to use for routing traffic to the targets and `target_type = ip` sets the type of target that the target group routes traffic to in this case
the targets are specified by IP address. 
 
```terraform
# Create a target group
resource "aws_lb_target_group" "target_group" {
  depends_on  = [aws_lb.lb]
  name        = var.target_group_name
  port        = var.container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
```

## Load balancer listener

The listener checks for connection requests from clients, using the protocol (TCP) and port (80) and redirect traffic from the load balancer to the target group. 

The `type` option defines the type of routing action. The `forward` type routes requests to one or more target groups.

```terraform
# Redirect traffic from the Load Balancer to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.container_port
  protocol          = "TCP"

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

```terraform
data "aws_iam_policy_document" "ecs_task_executor_policy" {
  statement {
    sid = 1
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:bedrock:log-stream:*"]
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

```terraform
data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid       = 1
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
  statement {
    sid       = 2
    actions   = ["bedrock:InvokeModel", "bedrock:ListCustomModels", "bedrock:ListFoundationModels"]
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

```python
@app.get("/", response_class=HTMLResponse)
async def root():
    """
    Endpoint for handling GET requests at the root path ("/").
    """
    ...
```

```python
@app.post("/ask")
async def question(body: Body):
    """
    Endpoint for handling POST requests at the "/ask" path.
    Receives a request body parameter named 'body' of type 'Body'.
    """    
    ...
```


## VPC Link

The VPC link facilitates the API Gateway's access to the Amazon ECS service running within the Amazon VPC. Subsequently, you establish an Rest or HTTP API that leverages the VPC link to establish a connection with the Amazon ECS service.

The `target_arns` argument receives a list of network load balancer arns in the VPC targeted by the VPC link. 

```terraform
# Create a VPC Link from the API Gateway to the Load Balancer
resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = var.vpc_link_name
  description = "VPC link for API Gateway"
  target_arns = [var.lb_arn]
  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
```

## API Gateway

The `aws_api_gateway_rest_api` are used for creating and deploying REST APIs

The `type` can be one the following type: EDGE, REGIONAL or PRIVATE

A regional API endpoint typically reduces connection latency when API requests predominantly originate 
from services within the same region as the deployed API.

```terraform
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway for REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

### Resource

A resource is a logical entity that an app can access through a resource path. The `path_part`
define last path segment of this API resource and is equal to the FastAPI path `@app.post("/ask")`.

```terraform
# Resource for POST /ask
resource "aws_api_gateway_resource" "ask_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ask"
}
```

### Method

A method corresponds to a REST API request that is submitted by the user. The method support HTTP verbs such as GET, POST, PUT, PATCH, and DELETE.

```terraform
# Resource for POST /ask
resource "aws_api_gateway_method" "ask_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ask_resource.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}
```

### Integration

The integration integrates the Rest API, the resource and the method. It also defines
the integration type (AWS, AWS_PROXY, HTTP, HTTP_PROXY, and MOCK), the HTTP method, the URI,
and the connection type.

The `HTTP_PROXY` type permit API Gateway passes the incoming request from the client to the HTTP endpoint and passes the outgoing response from the HTTP endpoint to the client. Setting the integration request or integration response is not required when utilizing the HTTP proxy type. More information: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-integration-types.html

```terraform
# Integration for POST /ask
resource "aws_api_gateway_integration" "ask_post_integration" {

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ask_resource.id
  http_method = aws_api_gateway_method.ask_post.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "http://${var.lb_dns_name}:${var.container_port}/ask"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
}
```


### Deploy

The `aws_api_gateway_deployment` make the API callable by users. More information: https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html


```terraform
# Create a API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.ask_post_integration,
    aws_api_gateway_integration.root_get_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  description = "Deployment for the dev stage"

  lifecycle {
    create_before_destroy = true # Without enabling create_before_destroy, API Gateway can return errors such as BadRequestException:
  }
}
```

### Stage

Each stage is a named reference to a deployment of the API and is made available for client applications to call.

```terraform
# Create a API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.api_stage_name

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}
```

### API Gateway Usage Plan

An API Gateway Usage Plan define who can access deployed API stages and methods. A quota define the maximum number of requests that can be made in a given time period and in which time period the limit applies. Throttle settings can be configured at the API or API method level, determining the maximum rate limit over a customizable time frame, ranging from one to a few seconds. Throttling initiates when the target point is reached.

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