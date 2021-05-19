terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.41.0"
    }
  }
  backend "s3" {
    bucket = "cloudcasts-terraform-fab"
    key    = "cloudcasts/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

variable "infra_env" {
  type        = string
  description = "infrastructure environment"
}

variable "default_region" {
  type        = string
  description = "the region this infrastructure is in"
  default     = "us-east-1"
}

variable "instance_size" {
  type        = string
  description = "ec2 web server size"
  default     = "t3.small"
}

data "aws_ami" "app" {

  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical official

}
resource "aws_instance" "cloudcasts_web" {
  ami           = data.aws_ami.app.id
  instance_type = var.instance_size

  root_block_device {
    volume_size = 8 # GB
    volume_type = "gp3"
  }
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "cloudcasts-${var.infra_env}-web"
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

resource "aws_eip" "cloudcasts_addr" {
  ## We're don't define an instance directly here,
  ## The reason is covered in the video
  # instance = aws_instance.cloudcasts_web.id

  vpc = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "cloudcasts-${var.infra_env}-web-address"
    Project     = "cloudcasts.io"
    Environment = var.infra_env
    ManagedBy   = "terraform"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.cloudcasts_web.id
  allocation_id = aws_eip.cloudcasts_addr.id
}
