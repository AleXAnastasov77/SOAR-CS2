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

source "amazon-ebs" "security-tools" {
  region                  = var.aws_region
  instance_type           = "t3.xlarge"
  ami_name                = "soar-security-tools-{{timestamp}}"
  #ami_name                = "soar-security-tools-full-{{timestamp}}"
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
#   source_ami_filter {
#     filters = {
#       name                = "openvas-1.0"
#       root-device-type    = "ebs"
#       virtualization-type  = "hvm"
#     }
#     owners      = ["self"]
#     most_recent = true
#   }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 60
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

build {
  name    = "security-tools-image"
  sources = ["source.amazon-ebs.security-tools"]

  provisioner "ansible" {
    playbook_file = "../ansible/main.yml"
    #extra_arguments = ["--tags", "security"]
    extra_arguments = ["--tags", "security,snort,filebeat,openvas"]
    ansible_env_vars = [
    "ANSIBLE_ROLES_PATH=../ansible/roles",
    "ANSIBLE_REMOTE_TEMP=/tmp/.ansible/tmp",
    "ANSIBLE_CONFIG=../ansible/ansible.cfg"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
