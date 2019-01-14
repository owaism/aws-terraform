output "dmz-subnet-ids" {
  value = ["${aws_subnet.dmz-subnets.*.id}"]
}


output "private-subnet-ids" {
  value = ["${aws_subnet.private-subnets.*.id}"]
}