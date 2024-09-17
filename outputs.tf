output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "The ID of the Internet Gateway"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of IDs of public subnets"
}

output "public_subnet_cidrs" {
  value       = aws_subnet.public[*].cidr_block
  description = "List of CIDR blocks of public subnets"
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}


output "bastion_private_key" {
  value     = tls_private_key.bastion.private_key_pem
  sensitive = true
}