# AWS Network

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

The VPC has two private subnets and two public subnets. Both subnets have a CIDR which must be 
a subset of the VPC CIDR `10.0.0.0/16`. The subnets configured in two different zones
increases the redundancy and fault tolerance.

AWS reserves five IP addresses in each subnet for routing, Domain Name System (DNS), and network management. 
The remaining IP addresses are diveded by the four subnets.

Directory: `terraform/network`

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

Directory: `terraform/network`

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

The Internet Gateway allows traffic to flow in and out of the VPC to the public internet. 
In this case, it will allow your ECS service to make outbound connections to Qdrant service 
hosted on Google Cloud.

Directory: `terraform/network`

```terraform
# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

## Route table 

The route table has a set of rules called routes that determine where the network traffic 
is directed. The route table allow traffic between all subnets to the VPC.

### Route table for public networks

Directory: `terraform/network`

```terraform
# Create a Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-route-table"
    Application = var.application_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.aws_public_subnet_cidr_blocks)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
}
```

### Route table for private subnets

Directory: `terraform/network`

```terraform
resource "aws_route_table" "private_route_table" {
  count  = length(var.aws_private_subnet_cidr_blocks)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }

  tags = {
    Name        = "private-route-table-${count.index}"
    Application = var.application_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.aws_private_subnet_cidr_blocks)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}
``` 

## NAT gateway

<p align="center">
<img src="https://github.com/mathewsrc/generativeai-questions-and-answers-app/assets/94936606/41e4d8de-5b0b-4636-83de-efc009ba4177" width=80%>
<p/>

Figure 2. Elastic Container Service communication with Qdrant Cloud using NAT gateway 

### Elastic IP

The elastic IP address is a static, IPv4 address designed for dynamic cloud computing.
The elastic IP provides a fixes, public IP address that routes to the NAT gateway.

Directory: `terraform/network`

```terrafom
# Create an Elastic IP address for the NAT Gateway
resource "aws_eip" "nat" {
  count      = length(var.aws_public_subnet_cidr_blocks)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}
```
### NAT gateway
The NAT gateway enables instances in a private subnet to connect to the internet, but prevents the internet
from initiating a connection with those instances. We need a NAT gateway to connect to the Qdrant Cloud service.

Directory: `terraform/network`

```terraform
# Create a NAT Gateway for the public subnets
# Required to allow the ECS tasks to access the internet and communicate with Qdrant Cloud
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.aws_public_subnet_cidr_blocks)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)

  tags = {
    Name        = "nat-gateway"
    Subnet      = "public"
    Application = var.application_name
    Environment = var.environment
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}
```

## Security groups


The security groups controls the imbound and outbound traffic from Load Balancer and
ECS tasks. 

Directory: `terraform/network`

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

## VPC Endpoints

VPC endpoints permit to access others AWS services from within the VPC without needing to traverse
the public internet

<p align="center">
<img src="https://github.com/mathewsrc/generativeai-questions-and-answers-app/assets/94936606/ec947f0c-d003-47b9-83b3-a7efd31b3548" width=80%>
<p/>

Figure 3. VPC endpoint example 


The ECR Docker endpoint permits ECS to pull Docker images. This endpoint's network interfaces is created in the private subnets and the security group rules are the same as the ECS tasks. More information: https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html

Directory: `terraform/network`

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

Directory: `terraform/network`

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

Directory: `terraform/network`

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

Directory: `terraform/network`

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

Directory: `terraform/network`

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

Directory: `terraform/network`

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

Directory: `terraform/network`

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

### VPC endpoint policy

Set of actions to create VPC endpoints

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpcEndpoint",
                "ec2:DescribeVpcEndpoints",
                "ec2:DeleteVpcEndpoints"
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1:*:route-table/*",
                "arn:aws:ec2:us-east-1:*:vpc-endpoint/*",
                "arn:aws:ec2:us-east-1:*:vpc/*",
                "arn:aws:ec2:us-east-1:*:subnet/*",
                "arn:aws:ec2:us-east-1:*:security-group/*"
            ]
        },
        {
            "Sid": "Statement2",
            "Effect": "Allow",
            "Action": [
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1:*:security-group/*"
            ]
        }
    ]
}
```
