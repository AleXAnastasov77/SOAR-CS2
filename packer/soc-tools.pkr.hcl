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

variable "aws_region" { default = "eu-central-1" }

source "amazon-ebs" "soc-tools" {
  region                  = var.aws_region
  instance_type           = "t3.medium"
  ami_name                = "soar-soc-tools-{{timestamp}}"
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
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

build {
  name    = "soc-tools-image"
  sources = ["source.amazon-ebs.soc-tools"]

  provisioner "ansible" {
    playbook_file = "../ansible/main.yml"
    extra_arguments = ["--tags", "soc-tools"]
  }

  post-processor "shell-local" {
  inline = [
    "aws ssm put-parameter --name /soar/ami/soc-tools --type String --overwrite --value '{{ .ArtifactId }}'"
    ]
  }
}
