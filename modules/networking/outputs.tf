output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Subnet IDs keyed by the caller-provided stable names."
  value       = { for name, subnet in aws_subnet.this : name => subnet.id }
}

