output "route_table_ids" {
  value = ["${aws_route_table.core-terraform-private-rt.*.id}"]
}