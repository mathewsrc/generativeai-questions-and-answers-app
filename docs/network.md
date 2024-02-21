# AWS Network

<p align="center">
<img src="https://github.com/mathewsrc/GenerativeAI-Questions-and-Answers-app-with-Bedrock-Langchain-and-FastAPI/assets/94936606/c083e363-e8fb-44ea-83b3-2b2696e0a078" width=80%>
<p/>

Figure 1. Elastic Container Service Network Architecture (some features were omitted for better visualization)

## AWS VPC

Directory: `terraform/network`

```terraform
variable "aws_vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for vpc"
}
```

IP address: `10.0.0.0` <br/>
IP range with CIDR notation: `10.0.0.0/16` <br/>
IP range:  the first 16 bits of the IP address are fixed and the rest are flexible

A single IP address is a 32 bits grouped into 8 bits

```
   10        0        0        0
00001010 00000000 00000000 00000000
     FIXED       |     FLEXIBLE
```

A IP range with the CIDR notation /16 create 2^(32-16) = 2^16 = 65,536 possible IP addresses.


## Subnets

Directory: `terraform/network`

The VPC has two private subnets and two public subnets. Both subnets have a CIDR which must be 
a subset of the VPC CIDR `10.0.0.0/16`. The subnets configured in two different zones
increases the redundancy and fault tolerance.

AWS reserves five IP addresses in each subnet for routing, Domain Name System (DNS), and network management. 
The remaining IP addresses are diveded by the four subnets.

```terraform
# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(var.aws_public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.aws_public_subnet_cidr_blocks, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  ...
}
```

```terraform
# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.aws_private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.aws_private_subnet_cidr_blocks, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  ...
}
```

## Internet gateway

Directory: `terraform/network`


The Internet Gateway allows traffic to flow in and out of the VPC to the public internet. 
In this case, it will allow your ECS service to make outbound connections to Qdrant service 
hosted on Google Cloud.

## Route table 

Directory: `terraform/network`

The route table has a set of rules called routes that determine where the network traffic 
is directed. The route table allow traffic between all subnets to the VPC.

## Security groups

Directory: `terraform/network`

The security groups controls the imbound and outbound traffic from Load Balancer and
ECS tasks. 

```terraform
# Create a security group for the load balancer
resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.main.id  
  name   = var.security_group_name_lb  

  # This ingress rule allows incoming HTTP traffic.
  ingress {
    from_port   = 80  # Allow port 80 (HTTP)
    to_port     = 80  # Allow port 80 (HTTP)
    protocol    = "tcp"  # The protocol that should be allowed.
    cidr_blocks = ["0.0.0.0/0"]  # This allows traffic from any IP address.
  }

  # This egress rule allows all outgoing traffic.
  egress {
    from_port   = 0  
    to_port     = 0  
    protocol    = "-1"  # This allows all protocols.
    cidr_blocks = ["0.0.0.0/0"]  # This allows traffic to any IP address.
  }
...
}
```

```terraform
# Create a security group for the ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name   = var.security_group_name_ecs_tasks
  vpc_id = aws_vpc.main.id

  # Allows incoming TCP traffic on the port specified by var.container_port from the IP 
  # addresses in the CIDR block specified by var.aws_vpc_cidr_block.
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  # Allows incoming TCP traffic on port 443 from the IP addresses in 
  # the CIDR block specified by var.# aws_vpc_cidr_block.
  # The security group attached to the VPC endpoint must allow incoming 
  # connections on TCP port 443 from the private subnet of the VPC.
  ingress {
    protocol    = "tcp"
    from_port   = 443 # Allow port 443 (HTTPS)
    to_port     = 443 # Allow port 443 (HTTPS)
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

  # Allows all outgoing traffic to any IP address (0.0.0.0/0) and any protocol
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allows outgoing TCP traffic on port 443 to the destinations specified by the
  # prefix list of your S3 VPC endpoint.
  egress {
    from_port = 443 # Allow port 443 (HTTPS)
    to_port   = 443 # Allow port 443 (HTTPS)
    protocol  = "tcp"
    prefix_list_ids = [
      aws_vpc_endpoint.s3.prefix_list_id
    ]
  }

  # Allows outgoing TCP traffic on port 443 to the IP addresses in the CIDR block
  # specified by var.aws_vpc_cidr_block.
  egress {
    from_port   = 443 # Allow port 443 (HTTPS)
    to_port     = 443 # Allow port 443 (HTTPS)
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr_block]
  }

...
}
```

VPC Endpoints

Directory: `terraform/network`

VPC endpoints permit to access others AWS services from within the VPC without needing to traverse
the public internet


The ECR Docker endpoint permits ECS to pull Docker images. This endpoint's network interfaces is created in the private subnets and the security group rules are the same as the ECS tasks. More information: https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html

```terraform
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]
...
}
```

The ECR API endpoint permits ECS push and pull Docker images to and from ECR. This endpoint's network 
interfaces is created in the private subnets and the security group rules are the same 
as the ECS tasks.

```terraform
# Create a VPC Endpoint for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

...
}
```

The  Secrets Manager Endpoint allow ECS to get secrets without leave the Amazon network

```terraform
# Create a VPC Endpoint for Secrests Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "Secrets Manager VPC Endpoint"
    Environment = var.environment
  }
}
```

The Cloudwatch endpoint permit to send logs from resources within your VPC to CloudWatch 

```terraform
# Create a VPC Endpoint for CloudWatch
resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets.*.id
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

...
}
```

The S3 endpoint permit to access S3 from within your VPC without needing to traverse the public internet.
The gateway endpoint is required because Amazon ECR uses Amazon S3 to store image layers. 

```terraform
# Create a VPC Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.main.default_route_table_id]

...
}
```
The  Bedrock Endpoint allow ECS to access Bedrock APIs 

```terraform
# Create a VPC endpoint for Bedrock
resource "aws_vpc_endpoint" "bedrock" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "Bedrock VPC Endpoint"
    Environment = var.environment
  }
}
```

The  Bedrock-runtime Endpoint allow ECS to access Bedrock inference API

```terraform
# Create a VPC endpoint for Bedrock runtime
resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_subnets.*.id

  security_group_ids = [
    aws_security_group.ecs_tasks.id,
  ]

  tags = {
    Name        = "Bedrock Runtime VPC Endpoint"
    Environment = var.environment
  }
}
```