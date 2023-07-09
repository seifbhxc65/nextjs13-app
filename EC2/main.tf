
provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                 = "default"
}

# Create a VPC
resource "aws_vpc" "next_vpc" {
  cidr_block = "10.0.0.0/16" # Make your own choice of ips ! 
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "next_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a Route Table and associate it with the public subnet
resource "aws_route_table" "next_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "next_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "next_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}
# Create a VPC
resource "aws_vpc" "next_vpc" {
  cidr_block = "10.0.0.0/16" # its ur choice !
}

# Create public and private subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a NAT Gateway for the private subnet to access the internet
resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "my_eip" {
  vpc = true
}

# Create security groups for EC2 instances
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for web instances"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Security group for app instances"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instances for the web and app tiers
resource "aws_instance" "web_instances" {
  count         = 2
  instance_type = "t2.micro"
  ami           = "ami-xxxxxxxx"  # Replace with your desired AMI ID

  subnet_id               = aws_subnet.public_subnet.id
  vpc_security_group_ids  = [aws_security_group.web_sg.id]

  tags = {
    Name = "Web Instance ${count.index + 1}"
  }
}

resource "aws_instance" "app_instances" {
  count         = 2
  instance_type = "t2.micro"
  ami           = "ami-xxxxxxxx"  # Replace with your desired AMI ID

  subnet_id               = aws_subnet.private_subnet.id
  vpc_security_group_ids  = [aws_security_group.app_sg.id]

  tags = {
    Name = "App Instance ${count.index + 1}"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id]
}

# Create a target group for the ALB
resource "aws_lb_target_group" "my_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"
}

# Attach the web instances to the target group
resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.web_instances.*.id
  port             = 80
}

# Create an RDS PostgreSQL instance
resource "aws_db_instance" "my_db_instance" {
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  name                 = "my-database"
  username             = "admin"
  password             = "password"
  allocated_storage    = 20
  storage_type         = "gp2"
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_group_name      = aws_db_subnet_group.my_db_subnet_group.name
}

# Create a subnet group for the RDS instance
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id]
}

# Output the DNS name of the ALB
output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}
