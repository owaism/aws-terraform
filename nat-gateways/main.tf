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
    key    = "state/nat-gateway.tfstate"
  }
}

resource "aws_nat_gateway" "nat-gateways" {
  count = "${var.count-nat-instances}"
  allocation_id = "${var.nat-eips[count.index]}"
  subnet_id     = "${var.dmz-subnets[count.index]}"

  tags = {
    Name = "dmz-${module.global-variables.availability-zones-short[count.index]}-subnet-nat"
  }
}