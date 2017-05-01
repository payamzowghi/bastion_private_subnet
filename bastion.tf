resource "aws_instance" "bastion" {

  ami             = "ami-a58d0dc5"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.key_name}"
  security_groups = ["${aws_security_group.bastion.id}"]

  subnet_id                   = "${aws_subnet.bastion.id}"
  associate_public_ip_address = true
  
  tags {
    Name = "bastion"
  }
}

resource "aws_security_group" "bastion" {
  name = "bastion"
  description = "Allow access from allowed_network via SSH"
  vpc_id = "${aws_vpc.vpc_bastion.id}"

  # SSH
  ingress  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  egress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.server.id}"]
  }

  tags = {
    Name = "sg_bastion"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = "${aws_vpc.vpc_bastion.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig_bastion.id}"
  }

  tags {
    Name = "bastion_route_table"
  }
}

resource "aws_subnet" "bastion" {
  vpc_id = "${aws_vpc.vpc_bastion.id}"
  availability_zone = "us-west-2a"
  cidr_block = "172.16.1.0/24"

  tags {
    Name = "bastion_subnet"
  }
}

resource "aws_route_table_association" "bastion" {
  subnet_id = "${aws_subnet.bastion.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

