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


resource "aws_route_table" "core-terraform-private-rt" {
  count = "${var.count-route-tables}"
  vpc_id = "${var.core-terraform-vpc-id}"

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id = "${var.nat-ids[count.index]}"
  }

  tags = {
    Name = "core-terraform-${module.global-variables.availability-zones-short[count.index]}-rt"
  }
}