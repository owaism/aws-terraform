###### Update the below with your key pair #####################

output "public_key_path" {
  value = "/Users/owais/.ssh/core-terraform.pub"
}

output "private_key_path" {
  value = "/Users/owais/.ssh/core-terraform"
}

###### Update the above with your key pair #####################


output "s3-bucket-name" {
  value = "opentext-core-terraform-poc"
}

output "aws_shared_creds_file" {
  value = "aws_creds.tfvars"
}

output "aws_creds_profile_name" {
  value = "core_terraform"
}


output "aws_region" {
  value     = "us-east-1"
}

output "aws_amis" {
  value = "${
    map(
      "us-east-1","ami-70dad51a"
      )}"
}

output "availability-zones" {
  value = "${
    map(
      "0","us-east-1b",
      "1","us-east-1c",
      "2","us-east-1d",
    )}"
}

output "availability-zones-short" {
  value = "${
    map(
      "0","1b",
      "1","1c",
      "2","1d",
    )}"
}


output "public-subnet-cidr-blocks" {
  value = "${
    map(
      "0","10.0.0.0/24",
      "1","10.0.1.0/24",
      "2","10.0.2.0/24",
    )}"
}


output "private-subnet-cidr-blocks" {
  value = "${
    map(
      "0","10.0.3.0/24",
      "1","10.0.4.0/24",
      "2","10.0.5.0/24",
    )}"
}
