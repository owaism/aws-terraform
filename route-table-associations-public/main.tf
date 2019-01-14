################################################
##    Setting up Global Variables             ##
################################################
module "global-variables" {
  source = ".././global-variables"
}

data "terraform_remote_state" "aws_route_table_association" {
  backend = "s3"
  config {
    bucket = "${module.global-variables.s3-bucket-name}"
    region = "${module.global-variables.aws_region}"
    shared_credentials_file = "${module.global-variables.aws_shared_creds_file}"
    profile = "${module.global-variables.aws_creds_profile_name}"
    key    = "state/route-table-associations.tfstate"
  }
}

resource "aws_route_table_association" "route-table-associations" {
  count="${var.subnet-count}"
  subnet_id = "${var.subnet-ids[count.index]}"
  route_table_id = "${var.route-table-id}"
}