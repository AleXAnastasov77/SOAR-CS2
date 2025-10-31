# Ubuntu server AMI

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# VPN CERT
data "aws_acm_certificate" "cert" {
  domain   = "server.vpn.internal"
  statuses = ["ISSUED"]
}
# SIEM AMI ID via Parameter Store
data "aws_ssm_parameter" "siem_ami" {
  name = "/soar/ami/siem"
}
data "aws_ssm_parameter" "security_ami" {
  name = "/soar/ami/security-tools"
}

data "aws_ssm_parameter" "soc_ami" {
  name = "/soar/ami/soc-tools"
}

# PYTHON SCRIPTS
