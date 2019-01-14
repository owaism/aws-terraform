################################################
##    Setting up Global Variables             ##
################################################
module "global-variables"{
  source = ".././global-variables"
}


data "terraform_remote_state" "aws_internet_gateway" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/igw.tfstate"
  }
}

resource "aws_internet_gateway" "core-terraform-igw" {
  vpc_id = "${var.core-terraform-vpc-id}"

  tags = {
    Name = "core-terraform-igw"
  }
}