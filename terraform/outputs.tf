
output "public_ip" {
  value = aws_instance.instance[0].public_ip
}

output "ssh_command" {
  value = "ssh -i ${local_sensitive_file.pem_file.filename} ubuntu@${aws_instance.instance[0].public_ip}"
}

output "all_public_ips" {
  value = aws_instance.instance.*.public_ip
}