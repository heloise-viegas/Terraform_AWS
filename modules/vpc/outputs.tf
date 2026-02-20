output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = [for subnet in aws_subnet.pub-subnet : subnet.id]
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = [for subnet in aws_subnet.priv-subnet : subnet.id]
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway (if created)"
  value       = aws_nat_gateway.ngw.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public-rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private-rt.id
}
