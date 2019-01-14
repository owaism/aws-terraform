/*output "private-sg-id" {
  value = "${aws_security_group.private-sg.id}"
}


output "elb-sg-id" {
  value = "${aws_security_group.elb-sg.id}"
}


output "bastion-sg-id" {
  value = "${aws_security_group.bastion-sg.id}"
}*/


output "private-sg" {
  value = "${
    map(
      "id","${aws_security_group.private-sg.id}"
      )}"
}


output "elb-sg" {
  value = "${
    map(
      "id","${aws_security_group.elb-sg.id}"
      )}"
}


output "bastion-sg" {
  value = "${
    map(
      "id","${aws_security_group.bastion-sg.id}"
      )}"
}