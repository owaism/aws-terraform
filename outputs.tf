output "address" {
  value = "${aws_elb.core-terraform-web-elb.dns_name}"
}