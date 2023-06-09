packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "rhel-9-base"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "ami_filter" {
  type    = string
  default = ""
}

variable "ami_subnet_id" {
  type    = string
  default = ""
}

variable "ami_vpc_id" {
  type    = string
  default = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "rhel9_base" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.small"
  region        = "${var.aws_region}"
  subnet_id     = "subnet-07b548e510fbc6e00"
  vpc_id        = "vpc-0e3737a7d61892856"
  source_ami_filter {
    filters = {
      image-id            = "ami-0858136e05d24c9c8"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  security_group_id       = "sg-0398f640773fcbae0"
  ssh_username            = "ec2-user"
  temporary_key_pair_type = "ed25519"
  ssh_interface           = "public_ip"
  pause_before_ssm        = "2m"
  communicator            = "ssh"
  iam_instance_profile    = "AWSPackerSSMRole"
}

build {
  name    = "rhel9-base"
  sources = [
    "source.amazon-ebs.rhel9_base"
  ]

  provisioner "shell" {
    inline = [
      "echo Provisioning RHEL9 Base AMI",
      "sudo dnf update -y"
    ]
  }

  provisioner "ansible" {
    playbook_file   = "./rhel9_aws_base.yml"
    user            = "ec2-user"
    use_proxy       =  false
    extra_arguments = [ 
        "-vv",
    ]
  }

}