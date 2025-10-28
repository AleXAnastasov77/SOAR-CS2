# ////////////////////// EC2 Gateway //////////////////////////
resource "aws_instance" "nat_gw_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.endpoints_sg.id]
  source_dest_check      = false
  user_data              = file("nat_gw.sh")
  subnet_id              = aws_subnet.public_cs2.id
  key_name               = "ansible-keypair"
  tags = {
    Name = "NAT Gateway"
  }
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
}
resource "aws_network_interface" "nat_private" {
  subnet_id       = aws_subnet.privateSIEM_cs2.id
  private_ips     = ["10.0.10.5"]
  security_groups = [aws_security_group.endpoints_sg.id]
  attachment {
    instance     = aws_instance.nat_gw_instance.id
    device_index = 1
  }
}


# ////////////////////// SAMPLE ENDPOINT //////////////////////////

resource "aws_instance" "sample_endpoint" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.endpoints_sg.id]
  subnet_id              = aws_subnet.public_cs2.id
  private_ip             = "10.0.1.10"
  key_name               = "ansible-keypair"
  user_data              = file("wazuhagents.sh")
  tags = {
    Name = "Sample Endpoint"
  }
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted = true
  }
}