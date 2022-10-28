output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_public1_id" {
  value = aws_subnet.public[0].id
}

output "subnet_public2_id" {
  value = aws_subnet.public[1].id
}

output "subnet_public3_id" {
  value = aws_subnet.public[2].id
}

output "subnet_private1_id" {
  value = aws_subnet.private[0].id
}

output "subnet_private2_id" {
  value = aws_subnet.private[1].id
}

output "subnet_private3_id" {
  value = aws_subnet.private[2].id
}

output "subnet_public_ids" {

  value = aws_subnet.public[*].id
}

output "subnet_private_ids" {

  value = aws_subnet.private[*].id
}

output "nat" {
    value = aws_nat_gateway.nat.id
}

output "rt_private" {
    value = aws_route_table.private.id
}

output "rt_association_private" {
    value = aws_route_table_association.private_subnet
}
