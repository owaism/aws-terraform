################################################
##    Setting up Global Variables             ##
################################################
module "global-variables"{
  source = ".././global-variables"
}

data "terraform_remote_state" "aws_eip" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/eip.tfstate"
  }
}

resource "aws_eip" "eip" {
  count = "${var.eip-count}"
  vpc      = "${var.vpc}"
}