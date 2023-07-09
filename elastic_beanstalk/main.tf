provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                 = "default"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a Route Table and associate it with the public subnet
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a security group for the EC2 instances
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Security group for web instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-application"
  description = "My Elastic Beanstalk Application"
}

# Create an Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "my_environment" {
  name        = "my-environment"
  application = aws_elastic_beanstalk_application.my_app.name
  solution_stack_name = "64bit Amazon Linux 2 v5.4.0 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "SecurityGroups"
    value     = aws_security_group.web_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "Subnets"
    value     = aws_subnet.public_subnet.id
  }
   # Output the environment URL
  depends_on = [aws_elastic_beanstalk_environment.my_environment]
  
  output "environment_url" {
    value = aws_elastic_beanstalk_environment.my_environment.endpoint_url
  }
}
