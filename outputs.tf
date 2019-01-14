output "address" {
  value = "After 3-4 minutes visit at http://${aws_elb.core-terraform-web-elb.dns_name}"
}