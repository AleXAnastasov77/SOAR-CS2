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


# ////////////////////// SAMPLE ENDPOINT //////////////////////////

resource "aws_instance" "sample_endpoint" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.endpoints_sg.id]
  subnet_id              = aws_subnet.public_cs2.id
  key_name               = "ansible-keypair"
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