output "bastion_host_dns" {
  value = "${aws_instance.bastion.public_dns}"
}
