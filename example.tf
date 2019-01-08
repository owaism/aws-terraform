################################################
##    Terraform backend                       ##
################################################
terraform {
  backend "s3" {
    bucket = "opentext-core-terraform-poc"
    key    = "backend"
    region = "us-east-1"
  	shared_credentials_file = "aws_creds.tfvars"
  	profile = "core_terraform"
  }
}

################################################
##    Terraform remote state                  ##
################################################



data "terraform_remote_state" "aws_instance" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/aws_instance.tfstate"
    region = "us-east-1"
  	shared_credentials_file = "aws_creds.tfvars"
  	profile = "core_terraform"
  }
}

################################################
##    AWS config                              ##
################################################

provider "aws" {
  region     = "us-east-1"
  shared_credentials_file = "aws_creds.tfvars"
  profile                 = "core_terraform"
}


################################################
##    Resource - VPC                          ##
################################################

data "terraform_remote_state" "aws_vpc" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/vpc.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_vpc" "core-terraform-vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "core-terraform-vpc"
  }
}


################################################
##    Resource - Security Groups              ##
################################################

resource "aws_security_group" "private-sg" {
  name        = "private-sg"
  description = "Security group for private components"
  vpc_id      = "${aws_vpc.core-terraform-vpc.id}"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "elb-sg" {
  name        = "elb-sg"
  description = "Security group for Load Balancers"
  vpc_id      = "${aws_vpc.core-terraform-vpc.id}"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = "${aws_vpc.core-terraform-vpc.id}"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


################################################
##    Resource - Internet Gateway             ##
################################################

data "terraform_remote_state" "aws_internet_gateway" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/igw.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_internet_gateway" "core-terraform-igw" {
  vpc_id = "${aws_vpc.core-terraform-vpc.id}"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  tags = {
    Name = "core-terraform-igw"
  }
}


################################################
##    Resource - Public Route Table           ##
################################################

data "terraform_remote_state" "aws_route_table" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/route_table.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_route_table" "core-terraform-public-rt" {
  vpc_id = "${aws_vpc.core-terraform-vpc.id}"

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.core-terraform-igw.id}"
  }

  depends_on = ["aws_internet_gateway.core-terraform-igw"]

  tags = {
    Name = "core-terraform-public-rt"
  }
}



################################################
##    Resource - DMZ Subnet                   ##
################################################

data "terraform_remote_state" "aws_subnet" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/subnet.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_subnet" "dmz-1b-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1b"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  tags = {
    Name = "dmz-1b-subnet"
  }
}

resource "aws_route_table_association" "dmz-1b-subnet-rt" {
  subnet_id      = "${aws_subnet.dmz-1b-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-public-rt.id}"

  depends_on = ["aws_subnet.dmz-1b-subnet","aws_route_table.core-terraform-public-rt"]
}

resource "aws_subnet" "dmz-1c-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1c"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  tags = {
    Name = "dmz-1c-subnet"
  }
}

resource "aws_route_table_association" "dmz-1c-subnet-rt" {
  subnet_id      = "${aws_subnet.dmz-1c-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-public-rt.id}"
  depends_on = ["aws_subnet.dmz-1c-subnet","aws_route_table.core-terraform-public-rt"]
}

resource "aws_subnet" "dmz-1d-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1d"

  depends_on = ["aws_vpc.core-terraform-vpc"]

  tags = {
    Name = "dmz-1d-subnet"
  }
}

resource "aws_route_table_association" "dmz-1d-subnet-rt" {
  subnet_id      = "${aws_subnet.dmz-1d-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-public-rt.id}"
  depends_on = ["aws_subnet.dmz-1d-subnet","aws_route_table.core-terraform-public-rt"]
}


################################################
##    Resource - EIP                          ##
################################################

data "terraform_remote_state" "aws_eip" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/eip.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_eip" "nat-1b-eip" {
  vpc      = true
}

resource "aws_eip" "nat-1c-eip" {
  vpc      = true
}

resource "aws_eip" "nat-1d-eip" {
  vpc      = true
}

################################################
##    Resource - NAT Gateway                  ##
################################################


data "terraform_remote_state" "aws_nat_gateway" {
  backend = "s3"
  config {
    bucket = "opentext-core-terraform-poc"
    key    = "state/eip.tfstate"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
  }
}

resource "aws_nat_gateway" "dmz-1b-subnet-nat" {
  allocation_id = "${aws_eip.nat-1b-eip.id}"
  subnet_id     = "${aws_subnet.dmz-1b-subnet.id}"

  depends_on = ["aws_subnet.dmz-1b-subnet","aws_eip.nat-1b-eip"]

  tags = {
    Name = "dmz-1b-subnet-nat"
  }
}

resource "aws_nat_gateway" "dmz-1c-subnet-nat" {
  allocation_id = "${aws_eip.nat-1c-eip.id}"
  subnet_id     = "${aws_subnet.dmz-1c-subnet.id}"

  depends_on = ["aws_subnet.dmz-1c-subnet","aws_eip.nat-1c-eip"]

  tags = {
    Name = "dmz-1c-subnet-nat"
  }
}


resource "aws_nat_gateway" "dmz-1d-subnet-nat" {
  allocation_id = "${aws_eip.nat-1d-eip.id}"
  subnet_id     = "${aws_subnet.dmz-1d-subnet.id}"

  depends_on = ["aws_subnet.dmz-1d-subnet","aws_eip.nat-1d-eip"]

  tags = {
    Name = "dmz-1d-subnet-nat"
  }
}


################################################
##    Resource - Private Route Table          ##
################################################

resource "aws_route_table" "core-terraform-1b-rt" {
  vpc_id = "${aws_vpc.core-terraform-vpc.id}"

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.dmz-1b-subnet-nat.id}"
  }

  depends_on = ["aws_nat_gateway.dmz-1b-subnet-nat"]

  tags = {
    Name = "core-terraform-1b-rt"
  }
}


resource "aws_route_table" "core-terraform-1c-rt" {
  vpc_id = "${aws_vpc.core-terraform-vpc.id}"

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.dmz-1c-subnet-nat.id}"
  }

  depends_on = ["aws_nat_gateway.dmz-1c-subnet-nat"]

  tags = {
    Name = "core-terraform-1c-rt"
  }
}

resource "aws_route_table" "core-terraform-1d-rt" {
  vpc_id = "${aws_vpc.core-terraform-vpc.id}"

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.dmz-1d-subnet-nat.id}"
  }

  depends_on = ["aws_nat_gateway.dmz-1d-subnet-nat"]

  tags = {
    Name = "core-terraform-1d-rt"
  }
}


################################################
##    Resource - Private Subnet               ##
################################################


resource "aws_subnet" "private-1b-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  depends_on = ["aws_route_table.core-terraform-1b-rt"]

  tags = {
    Name = "private-1b-subnet"
  }
}

resource "aws_route_table_association" "private-1b-subnet-rt" {
  subnet_id      = "${aws_subnet.private-1b-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-1b-rt.id}"

  depends_on = ["aws_subnet.private-1b-subnet"]
}


resource "aws_subnet" "private-1c-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1c"

  depends_on = ["aws_route_table.core-terraform-1c-rt"]

  tags = {
    Name = "private-1c-subnet"
  }
}

resource "aws_route_table_association" "private-1c-subnet-rt" {
  subnet_id      = "${aws_subnet.private-1c-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-1c-rt.id}"

  depends_on = ["aws_subnet.private-1c-subnet"]
}


resource "aws_subnet" "private-1d-subnet" {
  vpc_id     = "${aws_vpc.core-terraform-vpc.id}"
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1b"

  depends_on = ["aws_route_table.core-terraform-1d-rt"]

  tags = {
    Name = "private-1d-subnet"
  }
}

resource "aws_route_table_association" "private-1d-subnet-rt" {
  subnet_id      = "${aws_subnet.private-1d-subnet.id}"
  route_table_id = "${aws_route_table.core-terraform-1d-rt.id}"

  depends_on = ["aws_subnet.private-1d-subnet"]
}


################################################
##    Resource - Key Pair                     ##
################################################
resource "aws_key_pair" "core-terraform-key" {
  key_name   = "core-terraform-key"
  public_key = "${file(var.public_key_path)}"
}


################################################
##    Resource - Bastion Host                 ##
################################################


resource "aws_instance" "core-terraform-bastion" {
  connection {
    # The default username for our AMI
    user = "ubuntu"
  }

  instance_type = "t2.nano"

  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.core-terraform-key.id}"

  vpc_security_group_ids = ["${aws_security_group.bastion-sg.id}"]

  subnet_id = "${aws_subnet.dmz-1d-subnet.id}"

  associate_public_ip_address = true


  tags = {
    Name = "bastion-host"
  }
}


################################################
##    Resource - Web Nodes                    ##
################################################

resource "aws_instance" "core-terraform-web-1b" {
  connection {
    # The default username for our AMI
    type     = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.core-terraform-bastion.public_ip}"
    bastion_user = "ubuntu"
    bastion_port = "22"
    bastion_private_key = "${file(var.private_key_path)}"
  }

  instance_type = "t2.nano"

  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.core-terraform-key.id}"

  vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

  subnet_id = "${aws_subnet.private-1b-subnet.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }

  tags = {
    Name = "core-terraform-web-1b"
  }
}

resource "aws_instance" "core-terraform-web-1c" {
  connection {
    # The default username for our AMI
    type     = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.core-terraform-bastion.public_ip}"
    bastion_user = "ubuntu"
    bastion_port = "22"
    bastion_private_key = "${file(var.private_key_path)}"
  }

  instance_type = "t2.nano"

  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.core-terraform-key.id}"

  vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

  subnet_id = "${aws_subnet.private-1c-subnet.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }

  tags = {
    Name = "core-terraform-web-1c"
  }
}

resource "aws_instance" "core-terraform-web-1d" {
  connection {
    # The default username for our AMI
    type     = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
    bastion_host = "${aws_instance.core-terraform-bastion.public_ip}"
    bastion_user = "ubuntu"
    bastion_port = "22"
    bastion_private_key = "${file(var.private_key_path)}"
  }

  instance_type = "t2.nano"

  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.core-terraform-key.id}"

  vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

  subnet_id = "${aws_subnet.private-1d-subnet.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }


  tags = {
    Name = "core-terraform-web-1c"
  }
}



resource "aws_elb" "core-terraform-web-elb" {
  name = "core-terraform-web-elb"

  subnets         = ["${aws_subnet.dmz-1b-subnet.id}","${aws_subnet.dmz-1c-subnet.id}","${aws_subnet.dmz-1d-subnet.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  instances       = ["${aws_instance.core-terraform-web-1b.id}","${aws_instance.core-terraform-web-1c.id}","${aws_instance.core-terraform-web-1d.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
