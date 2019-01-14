output "eips" {
  value = ["${aws_eip.eip.*.id}"]
}