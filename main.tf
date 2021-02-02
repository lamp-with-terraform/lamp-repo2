# Setting up region
provider "aws" {
  region = "us-east-1"
}

#get AZ's details
data "aws_availability_zones" "availability_zones" {}

#create VPC
resource "aws_vpc" "lamp_vpc" {
cidr_block = "${var.vpc_cidr}"
#enable_dns_hostnames = true
tags {
Name = "lamp-vpc"
}
}

#create public subnet1
resource "aws_subnet" "lamp_vpc_public_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.public_subnet_cidr, 0)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
map_public_ip_on_launch = true
tags {
   Name = "lamp-vpc-public-subnet"
  }
}

#create public subnet2
resource "aws_subnet" "lamp_vpc_public2_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.public_subnet_cidr, 1)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
map_public_ip_on_launch = true
tags {
   Name = "lamp-vpc-public2-subnet"
  }
}

#create private subnet for app 1
resource "aws_subnet" "lamp_vpc_app1_private_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.app_private_subnet_cidr, 0)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
tags {
   Name = "app1-private_subnet"
  }
}

#create private subnet for app 2
resource "aws_subnet" "lamp_vpc_app2_private_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.app_private_subnet_cidr, 1)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
tags {
   Name = "app2-private_subnet"
  }
}

#create private subnet for db 1
resource "aws_subnet" "lamp_vpc_db1_private_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.db_private_subnet_cidr, 0)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[0]}"
tags {
   Name = "db-private_subnet1"
  }
}
resource "aws_subnet" "lamp_vpc_db2_private_subnet" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
cidr_block = "${element(var.db_private_subnet_cidr, 1)}"
availability_zone = "${data.aws_availability_zones.availability_zones.names[1]}"
tags {
   Name = "db-private_subnet2"
  }
}


#create internet gateway
resource "aws_internet_gateway" "lamp_internet_gateway" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
tags {
Name = "lamp-internet-gateway"
}
}

#create public route table (assosiated with internet gateway)
resource "aws_route_table" "lamp_public_subnet_route_table" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
route {
cidr_block = "${var.route_table_cidr}"
gateway_id = "${aws_internet_gateway.lamp_internet_gateway.id}"
}
tags {
Name = "lamp-public-subnet-route-table"
}
}
#create private subnet route table
resource "aws_route_table" "lamp_private_subnet_route_table" {
vpc_id = "${aws_vpc.lamp_vpc.id}"
route {
cidr_block = "${var.route_table_cidr}"
nat_gateway_id = "${aws_nat_gateway.lamp_ngw.id}"
}
tags {
Name = "lamp-private-subnet-route-table"
}
}

#create default route table
resource "aws_default_route_table" "lamp_main_route_table" {
default_route_table_id = "${aws_vpc.lamp_vpc.default_route_table_id}"
tags = {
Name = "lamp-main-route-table"
}
}

#assosiate public subnet with public route table
resource "aws_route_table_association" "lamp_public_subnet_route_table" {
subnet_id = "${aws_subnet.lamp_vpc_public_subnet.id}"
route_table_id = "${aws_route_table.lamp_public_subnet_route_table.id}"
}

resource "aws_route_table_association" "lamp_public2_subnet_route_table" {
subnet_id = "${aws_subnet.lamp_vpc_public2_subnet.id}"
route_table_id = "${aws_route_table.lamp_public_subnet_route_table.id}"
}

#assosiate private subnets with private route table
resource "aws_route_table_association" "lamp_app1_private_subnet_route_table_assosiation" {
subnet_id = "${aws_subnet.lamp_vpc_app1_private_subnet.id}"
route_table_id = "${aws_route_table.lamp_private_subnet_route_table.id}"
}
resource "aws_route_table_association" "lamp_app2_private_subnet_route_table_assosiation" {
subnet_id = "${aws_subnet.lamp_vpc_app2_private_subnet.id}"
route_table_id = "${aws_route_table.lamp_private_subnet_route_table.id}"
}
resource "aws_route_table_association" "lamp_db1_private_subnet_route_table_assosiation" {
subnet_id = "${aws_subnet.lamp_vpc_db1_private_subnet.id}"
route_table_id = "${aws_route_table.lamp_private_subnet_route_table.id}"
}
resource "aws_route_table_association" "lamp_db2_private_subnet_route_table_assosiation" {
subnet_id = "${aws_subnet.lamp_vpc_db2_private_subnet.id}"
route_table_id = "${aws_route_table.lamp_private_subnet_route_table.id}"
}

#creating elastic IP
#resource "aws_eip" "nat_eip" {
#  vpc = true
#}

#Creating Nat Gateway
resource "aws_nat_gateway" "lamp_ngw" {
  allocation_id = "eipalloc-071922b78721ff4ee"
  subnet_id = "${aws_subnet.lamp_vpc_public_subnet.id}"
  tags = {
    Name = "Lamp-NAT-Gateway"
  }
}

#create security group for web
resource "aws_security_group" "web_security_group" {
name = "web_security_group"
description = "Allow all inbound traffic"
vpc_id = "${aws_vpc.lamp_vpc.id}"
tags {
Name = "lamp-vpc-web-security-group"
}
}
#create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
count = "${length(var.web_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}
#create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
count = "${length(var.web_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.web_ports, count.index)}"
to_port = "${element(var.web_ports, count.index)}"
security_group_id = "${aws_security_group.web_security_group.id}"
}
#create security group for db
resource "aws_security_group" "db_security_group" {
name = "db_security_group"
description = "Allow all inbound traffic"
vpc_id = "${aws_vpc.lamp_vpc.id}"
tags {
Name = "lamp-vp-db-security-group"
}
}
#create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
count = "${length(var.db_ports)}"
type = "ingress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.db_ports, count.index)}"
to_port = "${element(var.db_ports, count.index)}"
security_group_id = "${aws_security_group.db_security_group.id}"
}
#create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
count = "${length(var.db_ports)}"
type = "egress"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
from_port = "${element(var.db_ports, count.index)}"
to_port = "${element(var.db_ports, count.index)}"
security_group_id = "${aws_security_group.db_security_group.id}"
}

#create db subnet groups
resource "aws_db_subnet_group" "db_subnet_group" {
name = "dbsg"
subnet_ids = ["${aws_subnet.lamp_vpc_db1_private_subnet.id}", "${aws_subnet.lamp_vpc_db2_private_subnet.id}"]
tags = {
Name = "application-subnet-group"
}
}

#create aws mysql rds instance
resource "aws_db_instance" "lamp_database_instance" {
allocated_storage = 20
storage_type = "gp2"
engine = "mysql"
engine_version = "5.7"
instance_class = "db.t2.micro"
port = 3306
vpc_security_group_ids = ["${aws_security_group.db_security_group.id}"]
db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
name = "mydb"
identifier = "mysqldb"
username = "lampuser"
password = "lamppassword"
parameter_group_name = "default.mysql5.7"
skip_final_snapshot = true
tags = {
Name = "lamp_database_instance"
}
}

# Getting id of ami
data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*-x86_64-gp2"]
  }
}

#Creating key pair
resource "aws_key_pair" "lamp_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#Creating lunch configuration
resource "aws_launch_configuration" "lamp_conf" {
  name = "lamplcong"
  image_id = "${data.aws_ami.server_ami.id}"
  instance_type = "t2.micro"
  user_data = <<-EOF
            #!/bin/bash
            sudo mkdir -p /var/www/html/
            sudo yum update -y
            sudo yum install -y httpd
            sudo service httpd start
            sudo service httpd enable
            sudo usermod -a -G apache ec2-user
            sudo chown -R ec2-user:apache /var/www
            sudo yum install -y mysql php php-mysql
            EOF
  security_groups = ["${aws_security_group.web_security_group.id}"]
  key_name = "${aws_key_pair.lamp_auth.id}"
  // If the launch_configuration is modified:
  // --> Create New resources before destroying the old resources
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "lamp_config" {
  name = "lampASG"
  max_size = 5
  min_size = 2
  launch_configuration = "${aws_launch_configuration.lamp_conf.name}"
  health_check_grace_period = 300 // Time after instance comes into service before checking health.
  health_check_type = "ELB" // ELB or Ec2 (Default):
  //availability_zones = ["us-east-1a"]
  // EC2 --> Minimal health check - consider the vm unhealthy if the Hypervisor says the vm is completely down
  // ELB --> Instructs the ASG to use the "target's group" health check

  vpc_zone_identifier = ["${aws_subnet.lamp_vpc_app1_private_subnet.id}", "${aws_subnet.lamp_vpc_app2_private_subnet.id}"] // A list of subnet IDs to launch resources in.
  // We specified all the subnets in the default vpc

  //target_group_arns = "aws_lb_target_group.asg.arn"

  tag {
    key = "name"
    value = "Lamp_ASG"
    propagate_at_launch = false
  }
  lifecycle {
  create_before_destroy = true
  }
}

# Creating application load balancer
resource "aws_lb" "lamp_lb" {
  name               = "lamplb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.web_security_group.id}"]
  subnets            = ["${aws_subnet.lamp_vpc_public_subnet.id}", "${aws_subnet.lamp_vpc_public2_subnet.id}"]
}  

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.lamp_lb.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.app_instances.arn}"
  }
}

resource "aws_lb_target_group" "app_instances" {
  name     = "ec2tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.lamp_vpc.id}"
}

#resource "aws_lb_target_group_attachment" "test" {
#  target_group_arn = "${aws_lb_target_group.app_instances.arn}"
#  target_id        = "${aws_instance.app_instances.id}"
#  port             = 80
#}

output "public_dns" {
value = "${aws_lb.lamp_lb.dns_name}"
}

