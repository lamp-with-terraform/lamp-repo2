variable "vpc_cidr" {
    default = "10.99.0.0/16"
}

variable "public_subnet_cidr" {
    default = ["10.99.1.0/24","10.99.2.0/24"]
}

variable "app_private_subnet_cidr" {
    default = ["10.99.11.0/24","10.99.12.0/24"]
}

variable "db_private_subnet_cidr" {
    default = ["10.99.21.0/24","10.99.22.0/24"]
}

variable "route_table_cidr" {
    default = "0.0.0.0/0"
}

variable "db_ports" {
    default = ["22", "3306"]
}

variable "web_ports" {
    default = ["22","80", "443", "3306"]
}


variable "key_name" {
    default = "lamp_key"
}

variable "public_key_path" {
    default = "/home/ec2-user/.ssh/id_rsa.pub"
}


