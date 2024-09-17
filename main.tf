# Provider configuration
provider "aws" {
  region = var.threetier_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = var.threetier_vpc
  }
}

# Provide info for what AZs to use
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.threetier_IGW
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.threetier_PublicSubnets} ${count.index + 1}"
  }
}

# Private Subnets (App Tier)
resource "aws_subnet" "private_app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.threetier_PrivateSubnets} ${count.index +1}"
  }
}

# Private Subnets (Database Tier)
resource "aws_subnet" "private_db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.threetier_DBSubnets} ${count.index +1}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = var.threetier_NATGateway
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = var.threetier_NATEIP
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = var.threetier_PublicRT
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = var.threetier_PrivateRT
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
  count          = 2
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb_external" {
  # Define rules for external ALB
  name        = "3tier-external-alb-sg"
  description = "Security group for external ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.threetier_externalALB_SG
  }
}

resource "aws_security_group" "alb_internal" {
  # Define rules for internal ALB
  name        = "3tier-internal-alb-sg"
  description = "Security group for internal ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from public EC2 instances"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.threetier_internalALB_SG
  }
}

resource "aws_security_group" "ec2_public" {
  # Define rules for public EC2 instances
  name        = "3tier-public-ec2-sg"
  description = "Security group for public EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from external ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_external.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.threetier_PublicEC2_SG
  }
}

resource "aws_security_group" "ec2_private" {
  # Define rules for private EC2 instances
  name        = "3tier-private-ec2-sg"
  description = "Security group for private EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from internal ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.threetier_PrivateEC2_SG
  }
}

resource "aws_security_group" "rds" {
  # Define rules for RDS
  name        = "3tier-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from private EC2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_private.id]
  }

  tags = {
    Name = var.threetier_RDS_SG
  }
}

resource "aws_security_group" "bastion" {
  # Define rules for Bastion host
  name        = "3tier-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.threetier_Bastion_SG
  }
}

# External ALB
resource "aws_lb" "external" {
  name               = "3tier-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_external.id]
  subnets            = aws_subnet.public[*].id
}

# Internal ALB
resource "aws_lb" "internal" {
  name               = "3tier-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = aws_subnet.private_app[*].id
}

# Auto Scaling Groups
resource "aws_launch_template" "public" {
  # Define launch template for public instances
  name_prefix   = "3tier-public-lt-"
  image_id      = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"  

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_public.id]
  }

  user_data = base64encode(<<-EOF
             #!/bin/bash
                                # Update the system
                                sudo yum -y update
                                # Install Apache web server
                                sudo yum -y install httpd
                                # Start Apache web server
                                sudo systemctl start httpd.service
                                # Enable Apache to start at boot
                                sudo systemctl enable httpd.service
                                # Create index.html file with your custom HTML
                                sudo echo '
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8" />
                                        <meta name="viewport" content="width=device-width, initial-scale=1" />
                                        <title>A Basic HTML5 Template</title>
                                        <link rel="preconnect" href="https://fonts.googleapis.com" />
                                        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
                                        <link
                                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700;800&display=swap"
                                            rel="stylesheet"
                                        />
                                        <link rel="stylesheet" href="css/styles.css?v=1.0" />
                                    </head>
                                    <body>
                                        <div class="wrapper">
                                            <div class="container">
                                                <h1>Welcome! An Apache web server has been started successfully.</h1>
                                                <h2></h2>
                                            </div>
                                        </div>
                                    </body>
                                </html>
                                <style>
                                    body {
                                        background-color: #34333D;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-family: Inter;
                                        padding-top: 128px;
                                    }
                                    .container {
                                        box-sizing: border-box;
                                        width: 741px;
                                        height: 449px;
                                        display: flex;
                                        flex-direction: column;
                                        justify-content: center;
                                        align-items: flex-start;
                                        padding: 48px 48px 48px 48px;
                                        box-shadow: 0px 1px 32px 11px rgba(38, 37, 44, 0.49);
                                        background-color: #5D5B6B;
                                        overflow: hidden;
                                        align-content: flex-start;
                                        flex-wrap: nowrap;
                                        gap: 24;
                                        border-radius: 24px;
                                    }
                                    .container h1 {
                                        flex-shrink: 0;
                                        width: 100%;
                                        height: auto; /* 144px */
                                        position: relative;
                                        color: #FFFFFF;
                                        line-height: 1.2;
                                        font-size: 40px;
                                    }
                                    .container p {
                                        position: relative;
                                        color: #FFFFFF;
                                        line-height: 1.2;
                                        font-size: 18px;
                                    }
                                </style>
                                ' > /var/www/html/index.html
                                EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.threetier_PublicEC2
    }
  }
}

resource "aws_autoscaling_group" "public" {
  # Define ASG for public instances
  name                = "3tier-public-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.public.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 500
  
  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.public.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.threetier_PublicASG_Instances
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "private" {
  # Define launch template for private instances
  name_prefix   = "3tier-private-lt-"
  key_name      = aws_key_pair.bastion.key_name
  image_id      = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_private.id]
  }

  user_data = base64encode(<<-EOF
             #!/bin/bash
                                # Update the system
                                sudo yum -y update
                                # Install Apache web server
                                sudo yum -y install httpd
                                # Start Apache web server
                                sudo systemctl start httpd.service
                                # Enable Apache to start at boot
                                sudo systemctl enable httpd.service
                                # Create index.html file with your custom HTML
                                sudo echo '
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8" />
                                        <meta name="viewport" content="width=device-width, initial-scale=1" />
                                        <title>A Basic HTML5 Template</title>
                                        <link rel="preconnect" href="https://fonts.googleapis.com" />
                                        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
                                        <link
                                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700;800&display=swap"
                                            rel="stylesheet"
                                        />
                                        <link rel="stylesheet" href="css/styles.css?v=1.0" />
                                    </head>
                                    <body>
                                        <div class="wrapper">
                                            <div class="container">
                                                <h1>Welcome! An Apache web server has been started successfully.</h1>
                                                <h2></h2>
                                            </div>
                                        </div>
                                    </body>
                                </html>
                                <style>
                                    body {
                                        background-color: #34333D;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-family: Inter;
                                        padding-top: 128px;
                                    }
                                    .container {
                                        box-sizing: border-box;
                                        width: 741px;
                                        height: 449px;
                                        display: flex;
                                        flex-direction: column;
                                        justify-content: center;
                                        align-items: flex-start;
                                        padding: 48px 48px 48px 48px;
                                        box-shadow: 0px 1px 32px 11px rgba(38, 37, 44, 0.49);
                                        background-color: #5D5B6B;
                                        overflow: hidden;
                                        align-content: flex-start;
                                        flex-wrap: nowrap;
                                        gap: 24;
                                        border-radius: 24px;
                                    }
                                    .container h1 {
                                        flex-shrink: 0;
                                        width: 100%;
                                        height: auto; /* 144px */
                                        position: relative;
                                        color: #FFFFFF;
                                        line-height: 1.2;
                                        font-size: 40px;
                                    }
                                    .container p {
                                        position: relative;
                                        color: #FFFFFF;
                                        line-height: 1.2;
                                        font-size: 18px;
                                    }
                                </style>
                                ' > /var/www/html/index.html
                                EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.threetier_PrivateEC2
    }
  }
}

resource "aws_autoscaling_group" "private" {
  # Define ASG for private instances
  name                = "3tier-private-asg"
  vpc_zone_identifier = aws_subnet.private_app[*].id
  target_group_arns   = [aws_lb_target_group.private.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 500
  
  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.private.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.threetier_PrivateASG_Instances
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "public" {
  name     = "3tier-public-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "private" {
  name     = "3tier-private-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private.arn
  }
}

resource "aws_lb_listener_rule" "public" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }

  condition {
    path_pattern {
      values = ["/public/*"]
    }
  }
}

resource "aws_lb_listener_rule" "private" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# RDS Instance
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = aws_subnet.private_db[*].id

  tags = {
    Name = var.threetier_RDS_Subnets
  }
}

resource "aws_db_instance" "main" {
  # Define RDS instance
  identifier        = "3tier-db-instance"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  
  db_name                = var.dbname
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = true
  storage_type           = "gp2"
  storage_encrypted      = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot    = true
  deletion_protection    = true

  tags = {
    Name = var.threetier_RDS_Instance
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  # Define Bastion host
  ami           = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.bastion.key_name

  tags = {
    Name = var.threetier_Bastion_Instance
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y ssh
              EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

# Generate RSA key pair
resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_secretsmanager_secret" "bastion_private_key" {
  name = "bastion-private-key"
}

resource "aws_secretsmanager_secret_version" "bastion_private_key" {
  secret_id     = aws_secretsmanager_secret.bastion_private_key.id
  secret_string = tls_private_key.bastion.private_key_pem
}

resource "aws_secretsmanager_secret" "bastion_public_key" {
  name = "bastion-public-key"
}

resource "aws_secretsmanager_secret_version" "bastion_public_key" {
  secret_id     = aws_secretsmanager_secret.bastion_public_key.id
  secret_string = tls_private_key.bastion.public_key_openssh
}