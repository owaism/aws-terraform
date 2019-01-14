################################################
##    Setting up Global Variables             ##
################################################
module "global-variables"{
  source = ".././global-variables"
}

data "terraform_remote_state" "aws_subnet" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/subnet.tfstate"
  }
}

resource "aws_subnet" "dmz-subnets" {
  count="${var.count-dmz-subnets}"
  vpc_id     = "${var.core-terraform-vpc-id}"
  cidr_block = "${module.global-variables.public-subnet-cidr-blocks[count.index]}"
  availability_zone = "${module.global-variables.availability-zones[count.index]}"

  tags = {
    Name = "dmz-${module.global-variables.availability-zones-short[count.index]}-subnet"
  }
}


resource "aws_subnet" "private-subnets" {
  count="${var.count-private-subnets}"
  vpc_id     = "${var.core-terraform-vpc-id}"
  cidr_block = "${module.global-variables.private-subnet-cidr-blocks[count.index]}"
  availability_zone = "${module.global-variables.availability-zones[count.index]}"

  tags = {
    Name = "private-${module.global-variables.availability-zones-short[count.index]}-subnet"
  }
}