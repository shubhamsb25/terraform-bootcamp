provider "aws" {
    region = "ap-south-1"
    access_key = "key"
    secret_key = "secret"
}

#1. define vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "name" = "production"
  }
}

#2. create internet gateway
resource "aws_internet_gateway" "prod-gateway" {
  vpc_id = aws_vpc.prod-vpc.id   
}

#3. create route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod-gateway.id
  }
 
  tags = {
    Name = "prod"
  }
}

#4. create subnet
resource "aws_subnet" "prod-subnet" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix
  availability_zone = "ap-south-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#5. associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6 create security group to allow traffic on port 22,80,443 (ssh,http,https)
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "Https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#7. Create network interface with an ip in the subnet created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#8. assign elastic ip to network interface create in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.prod-gateway
  ]
}

#9 create ubuntu server and install apache2
resource "aws_instance" "web_server_instance" {
    ami = "ami-06984ea821ac0a879"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    key_name = "terraform-tut"

    network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
    }

    user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo bash -c 'echo first server > /var/www/html/index.html' 
                EOF

    tags = {
        name="web-server"
    }
}

output "server_public_ip" {
    value = aws_eip.one.public_ip
}

output "server_private_ip" {
  value = aws_instance.web_server_instance.private_ip
}

output "server_instance_id" {
  value = aws_instance.web_server_instance.id
}



# terraform state list
# terraform state show <name>
# terraform refresh to see the outputs again so we dont have to do terraform apply again
# terraform apply -target <name of resource to delete>
# terraform destroy -target <name of resource to delete>
