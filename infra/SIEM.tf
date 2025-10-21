resource "aws_instance" "SIEM_instance" {
  ami                    = data.aws_ssm_parameter.siem_ami.value
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.SIEM_sg.id]
  subnet_id              = aws_subnet.privateSIEM_cs2.id
  private_ip             = "10.0.10.10"
  key_name               = "ansible-keypair"
  tags = {
    Name = "SIEM Server"
  }
  root_block_device {
    encrypted   = true
    volume_size = 50
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "required"
  }
  user_data = file("siem.sh")
}