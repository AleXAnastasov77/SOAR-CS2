resource "aws_instance" "SOC_Tools_instance" {
  ami                    = data.aws_ssm_parameter.soc_ami.value
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.SOCTools_sg.id]
  subnet_id              = aws_subnet.privateSOCTools_cs2.id
  private_ip             = "10.0.12.10"
  key_name               = "ansible-keypair"
  tags = {
    Name = "SOC Tools Server"
  }
  root_block_device {
    encrypted   = true
    volume_size = 30
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "required"
  }
}