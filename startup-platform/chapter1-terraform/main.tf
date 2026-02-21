terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "platform_key" {
  key_name   = "platform-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow SSH access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # tighten later
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
  }
}


resource "aws_instance" "platform" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t3.small"
  key_name      = aws_key_pair.platform_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  root_block_device {
    volume_size = 20
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "startup-platform-node"
  }
}
output "platform_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.platform.public_ip
}
