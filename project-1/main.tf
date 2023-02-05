# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  access_key = "key"
  secret_key = "secret"
}

resource "aws_instance" "my_ec2_instance" {
  ami           = "ami-00874d747dde814fa"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu_ec2"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "production"
  }
}