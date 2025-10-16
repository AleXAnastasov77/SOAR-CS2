resource "aws_vpc" "vpc_cs2" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_cs2"
  }
}
# ////////////////////// SUBNETS //////////////////////////
# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "public_cs2" {
  vpc_id                  = aws_vpc.vpc_cs2.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_cs2"
  }
}
resource "aws_subnet" "privateSIEM_cs2" {
  vpc_id     = aws_vpc.vpc_cs2.id
  cidr_block = "10.0.10.0/24"


  tags = {
    Name = "privateSIEM_cs2"
  }
}
resource "aws_subnet" "privateSecurityTools_cs2" {
  vpc_id     = aws_vpc.vpc_cs2.id
  cidr_block = "10.0.11.0/24"
  tags = {
    Name = "privateSecurityTools_cs2"
  }
}

resource "aws_subnet" "privateSOCTools_cs2" {
  vpc_id     = aws_vpc.vpc_cs2.id
  cidr_block = "10.0.12.0/24"
  tags = {
    Name = "privateSOCTools_cs2"
  }
}

# ////////////////////// GATEWAYS //////////////////////////
resource "aws_internet_gateway" "igw_cs2" {
  vpc_id = aws_vpc.vpc_cs2.id

  tags = {
    Name = "igw_cs2"
  }
}
# Allocate an Elastic IP for the NAT gateway
resource "aws_eip" "eip_natgw" {
  domain = "vpc"

  tags = {
    Name = "eip_natgw"
  }
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.nat_gw_instance.id
  allocation_id = aws_eip.eip_natgw.id
}


# ////////////////////// ROUTE TABLES //////////////////////////
resource "aws_route_table" "rt_public_cs2" {
  vpc_id = aws_vpc.vpc_cs2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_cs2.id
  }
  tags = {
    Name = "rt_public_cs2"
  }
}

resource "aws_route_table" "rt_private_cs2" {
  vpc_id = aws_vpc.vpc_cs2.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_gw_instance.primary_network_interface_id
  }
  tags = {
    Name = "rt_private_cs2"
  }
}

# ////////////////////// ROUTE TABLE ASSOCIATIONS //////////////////////////

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_cs2.id
  route_table_id = aws_route_table.rt_public_cs2.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.privateSIEM_cs2.id
  route_table_id = aws_route_table.rt_private_cs2.id
}
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.privateSOCTools_cs2.id
  route_table_id = aws_route_table.rt_private_cs2.id
}
resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.privateSecurityTools_cs2.id
  route_table_id = aws_route_table.rt_private_cs2.id
}

# ////////////////////// SECURITY GROUPS //////////////////////////
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "endpoints_sg" {
  name        = "endpoints-sg"
  description = "Allow SSH into the endpoints"
  vpc_id      = aws_vpc.vpc_cs2.id

  ingress {
    description = "Allow SSH from VPC CIDR (VPN included)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoints-sg"
  }
}
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "securitytools_sg" {
  name        = "securitytools_sg"
  description = "Open ports needed by Snort, OpenVAS"
  vpc_id      = aws_vpc.vpc_cs2.id

  ingress {
    description = "Allow SSH from VPC CIDR (VPN included)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "OpenVAS"
    from_port   = 9390
    to_port     = 9390
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "securitytools_sg"
  }
}
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "SOCTools_sg" {
  name        = "SOCTools_sg"
  description = "Open ports needed by The Misp, The Hive"
  vpc_id      = aws_vpc.vpc_cs2.id

  ingress {
    description = "Allow SSH from VPC CIDR (VPN included)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "MISP Web UI"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "MISP Web UI"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "The Hive"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SOCTools_sg"
  }
}
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "SIEM_sg" {
  name        = "SIEM-sg"
  description = "Opening ports needed for the SIEM"
  vpc_id      = aws_vpc.vpc_cs2.id
  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    description = "Allow SSH from VPC CIDR (VPN included)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Elasticsearch"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Kibana"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Logstash"
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Wazuh Manager"
    from_port   = 1514
    to_port     = 1514
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Wazuh Manager"
    from_port   = 1515
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }
  ingress {
    description = "Wazuh API"
    from_port   = 55000
    to_port     = 55000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.100.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SIEM-sg"
  }
}

# ////////////////////// VPN //////////////////////////
resource "aws_ec2_client_vpn_endpoint" "vpnendpoint_cs2" {
  description            = "VPN for monitoring access"
  server_certificate_arn = data.aws_acm_certificate.cert.arn
  client_cidr_block      = "10.100.0.0/16"
  dns_servers            = ["10.0.0.2"]
  vpc_id                 = aws_vpc.vpc_cs2.id
  split_tunnel           = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:eu-central-1:057827529833:certificate/54ab3b77-0344-4156-9c8b-620156c5e2d4"
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_ec2_client_vpn_network_association" "na_siem" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpnendpoint_cs2.id
  subnet_id              = aws_subnet.privateSIEM_cs2.id
}
resource "aws_ec2_client_vpn_route" "to_securitytools" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpnendpoint_cs2.id
  destination_cidr_block = aws_subnet.privateSecurityTools_cs2.cidr_block
  target_vpc_subnet_id   = aws_subnet.privateSIEM_cs2.id
}

resource "aws_ec2_client_vpn_route" "to_SOCTools" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpnendpoint_cs2.id
  destination_cidr_block = aws_subnet.privateSOCTools_cs2.cidr_block
  target_vpc_subnet_id   = aws_subnet.privateSIEM_cs2.id
}

resource "aws_ec2_client_vpn_authorization_rule" "authorization_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpnendpoint_cs2.id
  target_network_cidr    = aws_vpc.vpc_cs2.cidr_block
  authorize_all_groups   = true
}

# ////////////////////// Private DNS //////////////////////////
resource "aws_route53_zone" "private" {
  name = "innovatech.internal"

  vpc {
    vpc_id = aws_vpc.vpc_cs2.id
  }

}

resource "aws_route53_record" "SIEM" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "siem.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.SIEM_instance.private_ip]
}