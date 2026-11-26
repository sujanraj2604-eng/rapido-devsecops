terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "rapido_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "rapido-vpc"
  }
}

resource "aws_subnet" "rapido_subnet" {
  vpc_id                  = aws_vpc.rapido_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "rapido-public-subnet"
  }
}

resource "aws_internet_gateway" "rapido_igw" {
  vpc_id = aws_vpc.rapido_vpc.id

  tags = {
    Name = "rapido-igw"
  }
}

resource "aws_route_table" "rapido_route_table" {
  vpc_id = aws_vpc.rapido_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rapido_igw.id
  }

  tags = {
    Name = "rapido-public-route-table"
  }
}

resource "aws_route_table_association" "rapido_route_association" {
  subnet_id      = aws_subnet.rapido_subnet.id
  route_table_id = aws_route_table.rapido_route_table.id
}

resource "aws_security_group" "rapido_sg" {
  name        = "rapido-web-security-group"
  description = "Allow web traffic to Rapido demo"
  vpc_id      = aws_vpc.rapido_vpc.id

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "rapido-web-sg"
  }
}

resource "aws_instance" "rapido_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.rapido_subnet.id
  vpc_security_group_ids      = [aws_security_group.rapido_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    docker pull ${var.docker_image}

    docker run -d \
      --name rapido-app \
      --restart always \
      -p 80:80 \
      ${var.docker_image}
  EOF

  tags = {
    Name = "Rapido-Application-Server"
  }
}
