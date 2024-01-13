resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
  tags = {
    Name = "Default subnet for us-east-1a"
  }
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
  tags = {
    Name = "Default subnet for us-east-1b"
  }
}