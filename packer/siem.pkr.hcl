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

source "amazon-ebs" "siem" {
  region                  = "eu-central-1"
  instance_type           = "t3.large"
  ami_name                = "soar-siem-{{timestamp}}"
  ssh_username            = "ubuntu"

  source_ami_filter {
    filters = {
      name                 = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type     = "ebs"
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

  # keep AMI and snapshot even if the build fails
  force_deregister      = false
  force_delete_snapshot = false
}

build {
  name    = "siem-image"
  sources = ["source.amazon-ebs.siem"]

  provisioner "ansible" {
    playbook_file    = "../ansible/main.yml"
    extra_arguments  = ["--tags", "siem"]
  }

  # safer post-processor to store AMI ID in SSM Parameter Store
  post-processor "shell-local" {
    inline = [
      "AMI_ID=$(echo '{{ .ArtifactId }}' | cut -d':' -f2)",
      "aws ssm put-parameter --name /soar/ami/siem --type String --overwrite --value \"$AMI_ID\""
    ]
  }
}
