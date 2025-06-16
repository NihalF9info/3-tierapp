# Terraform provider setup
# {
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "profile-1"
}
# }


# Creating the VPC
# {{
resource "aws_vpc" "terra_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terra_vpc"
  }
}

# Creating the Internet Gateway
# {
resource "aws_internet_gateway" "terra_igw" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_igw"
  }
}
# }


# Creating the NAT Gateway
# {
resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip.id

  tags = {
    Name = "nat-gw"
  }
}
# Creating an Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}
# }


# Creating Route Tables
# {
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.terra_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_app_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-app-rt"
  }
}

resource "aws_route_table" "private_db_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "private-db-rt"
  }
}
# }


# Creating the Subnets
# {
resource "aws_subnet" "public_subnet-1" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "public_subnet-1"
  }
}

resource "aws_subnet" "private_subnet-1" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "private_subnet-1"
  }
}

resource "aws_subnet" "db_subnet-1" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "db_subnet-1"
  }
}

resource "aws_subnet" "public_subnet-2" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "public_subnet-2"
  }
}

resource "aws_subnet" "private_subnet-2" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "private_subnet-2"
  }
}

resource "aws_subnet" "db_subnet-2" {
  vpc_id            = aws_vpc.terra_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "db_subnet-2"
  }
}
# }


# Associating Route Tables to Subnets
# {
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet-1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id = aws_subnet.public_subnet-2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet-1.id
  route_table_id = aws_route_table.private_app_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id = aws_subnet.private_subnet-2.id
  route_table_id = aws_route_table.private_app_rt.id
}

resource "aws_route_table_association" "db_subnet_1_assoc" {
  subnet_id      = aws_subnet.db_subnet-1.id
  route_table_id = aws_route_table.private_db_rt.id
}

resource "aws_route_table_association" "db_subnet_2_assoc" {
  subnet_id = aws_subnet.db_subnet-2.id
  route_table_id = aws_route_table.private_db_rt.id
}
# }
# }}


# Creating the Security Groups
# {
# Web security_groups
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "web-sg"
  }
}

# App security_groups
resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "Application security group"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    description = "Allow HTTPS from web tier"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  ingress {
    description = "Allow HTTP from web tier"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

# Database security_groups
resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    description = "Allow MySql from app tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}
# }


# Creating a Web Server EC2 Instance
# {
resource "aws_instance" "web_server" {
  ami                    = "ami-015b1e8e2a6899bdb"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main_key.key_name
  subnet_id              = aws_subnet.public_subnet-1.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  associate_public_ip_address = true
  user_data = file("user_data_web.sh")

  tags = {
    Name = "web-server"
  }
}
# Creating a Key Pair for SSH access
resource "aws_key_pair" "main_key" {
  key_name   = "main-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
# }


# Creating an Application Server EC2 Instance
# {
resource "aws_instance" "app-server" {
  ami                    = "ami-015b1e8e2a6899bdb"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main_key.key_name
  subnet_id              = aws_subnet.private_subnet-1.id
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  associate_public_ip_address = false
  user_data = file("user_data_app.sh")

  tags = {
    Name = "app-server"
  }
}
# }

# Creating database instance
# {
# Creating variables for db username and password
variable "db_username" {
  description = "Username for RDS DB"
  type = string
  sensitive = true
  
}
variable "db_password" {
  description = "password for RDS DB"
  type = string
  sensitive = true
  
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.db_subnet-1.id, aws_subnet.db_subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mysqldb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  backup_retention_period          = 7
  storage_encrypted                = true
  iam_database_authentication_enabled = true

  publicly_accessible = false
  multi_az            = false

}
output "rds_endpoint" {
  value = aws_db_instance.default.endpoint
}
# }


# S3 bucket for storing application code
# {
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "threetier-app-code-nihal" 

  versioning {
    enabled    = true
    mfa_delete = true  # Note: This must be enabled manually in AWS console
  }

logging {
    target_bucket = "log-bucket-name"
    target_prefix = "log/"
  }

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
  
}
# block public access 
resource "aws_s3_bucket_public_access_block" "s3_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# }


# Creatong ALB
# {
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.web-sg.id]
  subnets = [
  aws_subnet.public_subnet-1.id,
  aws_subnet.public_subnet-2.id
]


  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# Target group for ALB 
resource "aws_lb_target_group" "alb-tg" {
  name        = "alb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.terra_vpc.id

}
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.app-server.id
  port             = 80
}

# Listener attachment 
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "alb-https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}
# }


# Creating Auto-Scaling Group 
# {
resource "aws_launch_template" "ec2-ami" {
  name_prefix   = "ec2-ami"
  image_id      = "ami-015b1e8e2a6899bdb"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "asg" {
  availability_zones = ["eu-west-1a", "eu-west-1b"]

  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  vpc_zone_identifier = [
    aws_subnet.private_subnet-1.id,
    aws_subnet.private_subnet-2.id
  ]

  launch_template {
    id      = aws_launch_template.ec2-ami.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.alb-tg.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}
# }










# resource "aws_network_interface" "web-server-nic" {
#     subnet_id   = aws_subnet.subnet-1.id
#     security_groups = [aws_security_group.main-sg.id]
#     private_ips = ["10.0.1.50"]
  
# }

# resource "aws_eip" "one" {
#     vpc = true
#     network_interface = aws_network_interface.web-server-nic.id
#     associate_with_private_ip = "10.0.1.50"
#      depends_on = [aws_instance.web-server-instance]
  
# }