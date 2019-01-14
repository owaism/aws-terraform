output "nat-gateways" {
  value = ["${aws_nat_gateway.nat-gateways.*.id}"]
}