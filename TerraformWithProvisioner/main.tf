terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

resource "aws_key_pair" "keyvalue" {
  key_name   = "terraform-demo-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "aws_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "aws_subnet" {
  vpc_id                  = aws_vpc.aws_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "aws_internet_gateway" {
  vpc_id = aws_vpc.aws_vpc.id
}
resource "aws_route_table" "aws_route_table" {
  vpc_id = aws_vpc.aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_internet_gateway.id
  }
}

resource "aws_route_table_association" "aws_route_table_association" {
  subnet_id      = aws_subnet.aws_subnet.id
  route_table_id = aws_route_table.aws_route_table.id
}

resource "aws_security_group" "sgp" {

  name = "aws_security_group-demo"

  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    name = "demo-aws_security_group"
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP FROM VPC"
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
}

resource "aws_instance" "demo_instance" {
  ami           = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.keyvalue.key_name
  vpc_security_group_ids = [
    aws_security_group.sgp.id
  ]
  subnet_id = aws_subnet.aws_subnet.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Provisioning EC2 instance...'",
      "sudo apt update -y",                                       # Update package lists
      "sudo apt-get install -y python3-pip",                      # Install pip for Python 3
      "sudo pip3 install flask",                                  # Install Flask
      "sudo nohup python3 /home/ubuntu/app.py > /dev/null 2>&1 &" # Run Flask app in the background
    ]
  }
}

