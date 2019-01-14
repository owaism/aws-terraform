
################################################
##    Terraform backend                       ##
################################################
terraform {
  backend "s3" {
    bucket = "opentext-core-terraform-poc"
    region = "us-east-1"
    shared_credentials_file = "aws_creds.tfvars"
    profile = "core_terraform"
    key    = "backend"
  }
}


################################################
##    Setting up Global Variables             ##
################################################
module "global-variables"{
  source = "./global-variables"
}


################################################
##    AWS config                              ##
################################################

provider "aws" {
  region = "${module.global-variables.aws_region}"
  shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
  profile = "${module.global-variables.aws_creds_profile_name}"
}


################################################
##    Terraform remote state                  ##
################################################

data "terraform_remote_state" "core-terraform" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/core-terraform.tfstate"
  }
}




################################################
##    Resource - VPC                          ##
################################################

data "terraform_remote_state" "aws_vpc" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/vpc.tfstate"
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
##    Setting up Security Groups              ##
################################################
module "security-groups"{
  source = "./security-groups"

  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
}




################################################
##    Resource - Internet Gateway             ##
################################################


module "internet-gateway"{
  source = "./internet-gateway"

  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
}


################################################
##    Resource - Public Route Table           ##
################################################

module "public-route-tables"{
  source = "./route-table-public"
  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
  core-terraform-igw-id = "${module.internet-gateway.core-terraform-igw-id}"
}



################################################
##    Resource - DMZ Subnets                  ##
################################################
module "dmz-subnets"{
  source = "./subnets"
  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
  count-dmz-subnets = "${var.az-count}"
}
################################################
## Resource - DMZ Subnets-Route Table Assoc   ##
################################################

module "public-route-table-associations"{
  source = "./route-table-associations-public"
  subnet-count = "${var.az-count}"
  subnet-ids = "${module.dmz-subnets.dmz-subnet-ids}"
  route-table-id = "${module.public-route-tables.route-table-id}"
}




################################################
##    Resource - EIP                          ##
################################################

module "nat-eips"{
  source = "./eip"
  eip-count = "${var.az-count}"
  vpc = true
}


################################################
##    Resource - NAT Gateway                  ##
################################################


module "nat-gateways"{
  source = "./nat-gateways"
  nat-eips = "${module.nat-eips.eips}"
  dmz-subnets = "${module.dmz-subnets.dmz-subnet-ids}"
  count-nat-instances = "${var.az-count}"
}


################################################
##    Resource - Private Route Table          ##
################################################

module "private-route-tables"{
  source = "./route-table-private"

  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
  nat-ids = "${module.nat-gateways.nat-gateways}"
  count-route-tables = "${var.az-count}"
}


################################################
##    Resource - Private Subnet               ##
################################################


module "private-subnets"{
  source = "./subnets"
  core-terraform-vpc-id = "${aws_vpc.core-terraform-vpc.id}"
  count-private-subnets = "${var.az-count}"
  count-dmz-subnets = 0
}


module "private-route-table-associations"{
  source = "./route-table-associations-private"
  subnet-ids = "${module.private-subnets.private-subnet-ids}"
  route-table-ids = "${module.private-route-tables.route_table_ids}"
  count-associations = "${var.az-count}"
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

  vpc_security_group_ids = ["${module.security-groups.bastion-sg["id"]}"]

  subnet_id = "${module.dmz-subnets.dmz-subnet-ids[0]}"

  associate_public_ip_address = true


  tags = {
    Name = "bastion-host"
  }
}


################################################
##    Resource - Web Nodes                    ##
################################################

resource "aws_instance" "core-terraform-web" {

  count = "${var.web-node-count}"
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

  vpc_security_group_ids = ["${module.security-groups.private-sg["id"]}"]

  subnet_id = "${module.private-subnets.private-subnet-ids[count.index]}"

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
    Name = "core-terraform-web-${module.global-variables.availability-zones-short[count.index]}"
  }
}




resource "aws_elb" "core-terraform-web-elb" {
  name = "core-terraform-web-elb"

  subnets         = ["${module.dmz-subnets.dmz-subnet-ids}"]
  security_groups = ["${module.security-groups.elb-sg["id"]}"]
  instances       = ["${aws_instance.core-terraform-web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
