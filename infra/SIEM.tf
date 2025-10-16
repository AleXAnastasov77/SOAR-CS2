resource "aws_instance" "SIEM_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.SIEM_sg.id]
  subnet_id              = aws_subnet.privateSIEM_cs2.id
  private_ip             = "10.0.10.10"
  key_name               = "ansible-keypair"
  tags = {
    Name = "SIEM Server"
  }
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_tokens = "required"
  }
}