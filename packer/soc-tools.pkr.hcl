packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" { default = "eu-west-1" }

source "amazon-ebs" "siem" {
  region                  = var.aws_region
  instance_type           = "t3.medium"
  ami_name                = "soar-siem-{{timestamp}}"
  ssh_username            = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type  = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  name    = "siem-image"
  sources = ["source.amazon-ebs.siem"]

  provisioner "ansible" {
    playbook_file = "../ansible/main.yml"
    extra_arguments = ["--tags", "soc-tools"]
  }

  post-processor "shell-local" {
    inline = [
      "aws ssm put-parameter --name '/soar/ami/soc-tools' --type String --overwrite --value {{ .ArtifactId }}"
    ]
  }
}
