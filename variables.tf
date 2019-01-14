
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "public_key_path" {
  description = "Path to the public ssh key on your machine"
  default = "/Users/owais/.ssh/core-terraform.pub"
}

variable "private_key_path" {
  description = "Path to the private ssh key on your machine"
  default = "/Users/owais/.ssh/core-terraform"
}


variable "aws_amis" {
  default = {
    us-east-1 = "ami-70dad51a"
  }
}

variable "az-count" {
  default = 3
}

variable "web-node-count" {
  default = 3
}

variable "availability-zones" {
  description = "availability-zones to be used for this infrastructure"
  type = "map"

  default = {
    "0" = "us-east-1b"
    "1" = "us-east-1c"
    "2" = "us-east-1d"
  }
}