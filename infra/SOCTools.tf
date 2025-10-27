resource "aws_instance" "Security_Tools_instance" {
  ami                    = "soar-security-tools-1761149231"
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.securitytools_sg.id]
  subnet_id              = aws_subnet.privateSecurityTools_cs2.id
  private_ip             = "10.0.11.1"
  key_name               = "ansible-keypair"
  tags = {
    Name = "Security Tools Server"
  }
  root_block_device {
    encrypted   = true
    volume_size = 50
    volume_type = "gp3"
  }
  metadata_options {
    http_tokens = "required"
  }
}