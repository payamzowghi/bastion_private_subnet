#Use AWS as provider
provider "aws" {
  region = "${var.region}"
}

#aws_vpc resource
resource "aws_vpc" "vpc_bastion" { 
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"

 tags {
   Name = "${var.name}"
 }
}

#private subnet
resource "aws_subnet" "private_subnet" {
 vpc_id                  = "${aws_vpc.vpc_bastion.id}"
 cidr_block              = "172.16.4.0/24"
 
 tags {
   Name = "private_subnet"
 }
}

#The aws_internet_gateway resource 
resource "aws_internet_gateway" "ig_bastion" {
  vpc_id = "${aws_vpc.vpc_bastion.id}"

  tags {
    Name = "igw"
  }
}

#The aws_route_private_subnet
resource "aws_route_table" "rt_private_subnet" {
  vpc_id = "${aws_vpc.vpc_bastion.id}"
  
route {
  cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_nat_gateway.nat_gw.id}"
}

  tags {
    Name = "rt_private_subnet"
  }
}

#The aws_route_table_association_private_subnet
resource "aws_route_table_association" "rt_association_private_subnet" {
  subnet_id      = "${aws_subnet.private_subnet.id}"
  route_table_id = "${aws_route_table.rt_private_subnet.id}"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.bastion.id}"
}


#security group_for server 
resource "aws_security_group" "server" {
  vpc_id      = "${aws_vpc.vpc_bastion.id}"
  description = "security-group-server"  
   
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "sg_server"
  }
}

data "template_file" "index" {
  template = "${file("files/index.html.tpl")}"
  
  vars {
    hostname = "server"
  }
}

resource "aws_instance" "server" {
  ami                         = "ami-a58d0dc5"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  subnet_id                   = "${aws_subnet.private_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.server.id}"]

  tags {
    Name = "server"
  }
  
  connection {
    user                = "ubuntu"  
    bastion_host        = "${aws_instance.bastion.public_dns}" 
    bastion_user        = "ubuntu"
    bastion_port        = 22
    bastion_private_key = "${file("/home/payamzowghi/.ssh/wordpress_key.pem")}"
    host                = "${self.private_ip}"
    private_key         = "${file("/home/payamzowghi/.ssh/wordpress_key.pem")}"
  }
 
  provisioner "file" {
     content     = "${data.template_file.index.rendered}"
     destination = "/tmp/index.html"
  } 
 
  provisioner "file" {
     source      = "files/bootstrap_puppet_args.sh"
     destination = "/tmp/bootstrap_puppet_args.sh"
  }
  
  provisioner "remote-exec" {
     inline = ["chmod +x /tmp/bootstrap_puppet_args.sh","/tmp/bootstrap_puppet_args.sh server=puppet.example.com"]
  }
  
  provisioner "remote-exec" {
     inline = ["sudo mv /tmp/index.html /var/www/html/index.html"]
  }
}




