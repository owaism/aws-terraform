################################################
##    Setting up Global Variables             ##
################################################
module "global-variables"{
  source = ".././global-variables"
}

data "terraform_remote_state" "aws_route_table" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/route_table.tfstate"
  }
}

resource "aws_route_table" "route-table" {

  vpc_id = "${var.core-terraform-vpc-id}"

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id = "${var.core-terraform-igw-id}"
  }

  tags = {
    Name = "core-terraform-public-rt"
  }
}