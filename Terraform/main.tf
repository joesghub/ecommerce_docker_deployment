provider "aws" {
  access_key = aws_access_keyvar.          # Replace with your AWS access key ID (leave empty if using IAM roles or env vars)
  secret_key = var.aws_secret_key          # Replace with your AWS secret access key (leave empty if using IAM roles or env vars)
  region     = "us-east-1" # Specify the AWS region where resources will be created (e.g., us-east-1, us-west-2)

}



## VPCS ##
# Custom VPC wl5vpc
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wl5vpc"
  }
}


resource "aws_vpc_peering_connection" "vpc_peer" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = aws_vpc.default.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between wl5vpc and default"
  }
}


# Data source to access the default route table of the default VPC
data "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
}

# Add a route for VPC peering to the default route table
resource "aws_route" "vpc_peering_route" {
  route_table_id            = data.aws_route_table.default.id
  destination_cidr_block    = aws_vpc.main.cidr_block  # Adjust based on peer VPC
  vpc_peering_connection_id  = aws_vpc_peering_connection.vpc_peer.id
}



## PUBLIC SUBNETS ##
# PUBLIC SUBNET 1A 
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1A"
  }
}
# PUBLIC SUBNET 1B 
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1B"
  }
}




## PRIVATE SUBNETS ##
# PRIVATE SUBNET 1A 
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet 1A"
  }
}
# PRIVATE SUBNET 1B  
resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private Subnet 1B"
  }
}




## SECURITY GROUPS ##
# FRONTEND SECURITY GROUP
resource "aws_security_group" "frontend_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "tf_frontend_sg"  #In AWS
  description = "SSH and Node.js" #In AWS
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags for the security group
  tags = {
    "Name" : "Frontend Security Group" # Name tag for the security group
    "Terraform" : "true"               # Custom tag to indicate this SG was created with Terraform
  }
}
# BACKEND SECURITY GROUP
resource "aws_security_group" "backend_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "tf_backend_sg"  #In AWS
  description = "SSH and Django" #In AWS
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/20"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags for the security group
  tags = {
    "Name" : "Backend Security Group" # Name tag for the security group
    "Terraform" : "true"              # Custom tag to indicate this SG was created with Terraform
  }
}
# LOAD BALANCER SECURITY GROUP
resource "aws_security_group" "loadbalancer_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "tf_loadbalancer_sg" #In AWS
  description = "SSH and HTTP"       #In AWS
  # Ingress rules: Define inbound traffic that is allowed.Allow SSH traffic and HTTP traffic on port 8080 from any IP address (use with caution)

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rules: Define outbound traffic that is allowed. The below configuration allows all outbound traffic from the instance.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags for the security group
  tags = {
    "Name" : "Load Balancer Security Group" # Name tag for the security group
    "Terraform" : "true"                    # Custom tag to indicate this SG was created with Terraform
  }
}





## GATEWAYS AND ELASTIC IP ##
# INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Ecommerce Internet Gateway"
  }
}
# ELASTIC IP
resource "aws_eip" "sticky_ip" {
  domain = "vpc"
}
# NAT GATEWAY
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.sticky_ip.id
  subnet_id     = aws_subnet.public_1a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT Gateway"
  }
}

# ELASTIC IP 2
resource "aws_eip" "sticky_ip_2" {
  domain = "vpc"
}
# NAT GATEWAY 2
resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.sticky_ip_2.id
  subnet_id     = aws_subnet.public_1b.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT Gateway 2"
  }
}




## ROUTE TABLES ##
# PUBLIC ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peer.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
# Associate Route Table with Public Subnets
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}



# PRIVATE ROUTE TABLE A
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  route {
    cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peer.id
  }

  tags = {
    Name = "Private Route Table"
  }
}
# Associate Route Table with Private Subnets 
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_a.id
}


# PRIVATE ROUTE TABLE B
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  route {
    cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peer.id
  }

  tags = {
    Name = "Private Route Table"
  }
}
resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_b.id
}





## BACKEND EC2S ##
# Backend EC2 1A
resource "aws_instance" "ecommerce_app_az1" {
  ami           = "ami-0866a3c8686eaeeba" # The Amazon Machine Image (AMI) ID used to launch the EC2 instance. Replace this with a valid AMI ID
  instance_type = "t3.micro"              # Specify the desired EC2 instance size.
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.backend_sg.id] # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name               = "workload_5"                       # The key pair name for SSH access to the instance.
  subnet_id              = aws_subnet.private_1a.id
  user_data = base64encode(templatefile("${path.module}/deploy.sh", {
    rds_endpoint = aws_db_instance.main.endpoint,
    docker_user = var.dockerhub_username,
    docker_pass = var.dockerhub_password,
    docker_compose = templatefile("${path.module}/compose.yml", {
      rds_endpoint = aws_db_instance.main.endpoint
    })
  }))

    depends_on = [
    aws_db_instance.main,
    aws_nat_gateway.main
  ]

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_backend_az1"
  }
}
# Backend EC2 1B
resource "aws_instance" "ecommerce_app_az2" {
  ami           = "ami-0866a3c8686eaeeba" # The Amazon Machine Image (AMI) ID used to launch the EC2 instance. Replace this with a valid AMI ID
  instance_type = "t3.micro"              # Specify the desired EC2 instance size.
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.backend_sg.id] # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name               = "workload_5"                       # The key pair name for SSH access to the instance.
  subnet_id              = aws_subnet.private_1b.id
  user_data = base64encode(templatefile("${path.module}/deploy.sh", {
    rds_endpoint = aws_db_instance.main.endpoint,
    docker_user = var.dockerhub_username,
    docker_pass = var.dockerhub_password,
    docker_compose = templatefile("${path.module}/compose.yml", {
      rds_endpoint = aws_db_instance.main.endpoint
    })
  }))

    depends_on = [
    aws_db_instance.main,
    aws_nat_gateway.main
  ]

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_backend_az2"
  }
}
output "ec2_back_1a_private_ip" {
  value = aws_instance.ec2_back_1a.private_ip
}
output "ec2_back_1b_private_ip" {
  value = aws_instance.ec2_back_1b.private_ip
}





## FRONTEND EC2S ##
# FRONTEND EC2 1A
resource "aws_instance" "ecommerce_bastion_az1" {
  ami           = "ami-0866a3c8686eaeeba" # The Amazon Machine Image (AMI) ID used to launch the EC2 instance. Replace this with a valid AMI ID
  instance_type = "t3.micro"              # Specify the desired EC2 instance size.
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name               = "workload_5"                        # The key pair name for SSH access to the instance.
  subnet_id              = aws_subnet.public_1a.id
  user_data = templatefile("/home/ubuntu/ecommerce_terraform_deployment/Scripts/frontend_build.sh", {
    ssh_key = var.ssh_key
  })

    depends_on = [
    aws_db_instance.main,
    aws_nat_gateway.main
  ]

  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_frontend_az1"
  }
}
# FRONTEND EC2 1B
resource "aws_instance" "ecommerce_bastion_az2" {
  ami           = "ami-0866a3c8686eaeeba" # The Amazon Machine Image (AMI) ID used to launch the EC2 instance. Replace this with a valid AMI ID
  instance_type = "t3.micro"              # Specify the desired EC2 instance size.
  # Attach an existing security group to the instance.
  # Security groups control the inbound and outbound traffic to your EC2 instance.
  vpc_security_group_ids = [aws_security_group.frontend_sg.id] # Replace with the security group ID, e.g., "sg-01297adb7229b5f08".
  key_name               = "workload_5"                        # The key pair name for SSH access to the instance.
  subnet_id              = aws_subnet.public_1b.id
  user_data = templatefile("/home/ubuntu/ecommerce_terraform_deployment/Scripts/frontend_build.sh")

    depends_on = [
    aws_db_instance.main,
    aws_nat_gateway.main
  ]


  # Tagging the resource with a Name label. Tags help in identifying and organizing resources in AWS.
  tags = {
    "Name" : "ecommerce_frontend_az2"
  }
}
output "ec2_instance_ids" {
  value = [aws_instance.ec2_front_1a.id, aws_instance.ec2_front_1b.id]
}



#############################
##     LOAD BALANCER       ##
resource "aws_lb" "ecommerce_lb" {
  name               = "tfecommerce-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}
resource "aws_lb_target_group" "tg" {
  name     = "test-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ecommerce_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
resource "aws_lb_target_group_attachment" "tg_attachments" {
  for_each = {
    "ec2_front_1a" = aws_instance.ecommerce_bastion_az1.id
    "ec2_front_1b" = aws_instance.ecommerce_bastion_az2.id
  } # List of instance IDs
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value
  port             = 80
}



##############
##   RDS    ##
##############

# AWS RDS
resource "aws_db_instance" "main" {
  identifier           = "ecommerce-db"
  engine               = "postgres"
  engine_version       = "14.13"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "standard"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.rds_db_pw
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "Ecommerce Postgres DB"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

