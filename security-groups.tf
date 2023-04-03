resource "aws_security_group" "wordpress_lb" {
  name        = "${local.project_name}-wordpress-lb"
  description = "Allow burendo.com website inbound traffic"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    description = "Allow website traffic from 0.0.0.0/0"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow website traffic from 0.0.0.0/0"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "wordpress_srv" {
  name        = "${local.project_name}-wordpress-srv"
  description = "Allow website inbound traffic"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    description     = "Allow website traffic from 0.0.0.0/0"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_lb.id]
  }

  ingress {
    description     = "Allow traffic from VPC endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_endpoints.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${local.project_name}-wordpress-srv"
  }
}

# Created as a seperate rule to get around Terraform Cycle dep issue
resource "aws_security_group_rule" "wordpress_srv_egress" {
  security_group_id        = aws_security_group.wordpress_srv.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = aws_security_group.wordpress_endpoints.id
}

resource "aws_security_group" "wordpress_endpoints" {
  name        = "${local.project_name}-wordpress-endpoints"
  description = "Allow traffic between VPC endpoints"
  vpc_id      = aws_vpc.wordpress.id

  tags = {
    Name = "${local.project_name}-wordpress-endpoints"
  }
}

# Created as a seperate rule to get around Terraform Cycle dep issue
resource "aws_security_group_rule" "wordpress_endpoints_egress" {
  security_group_id        = aws_security_group.wordpress_endpoints.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = aws_security_group.wordpress_srv.id
}

resource "aws_security_group_rule" "wordpress_endpoints_ingress" {
  security_group_id        = aws_security_group.wordpress_endpoints.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  type                     = "ingress"
  source_security_group_id = aws_security_group.wordpress_srv.id
}

resource "aws_security_group" "rds" {
  name        = "${local.project_name}-wordpress-rds"
  description = "Allow database inbound traffic from within VPC"
  vpc_id      = aws_vpc.wordpress.id

  ingress {
    description = "Allow database traffic from website servers"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.public_wordpress : subnet.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${local.project_name}-wordpress-db"
  }
}
