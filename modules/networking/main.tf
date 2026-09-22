locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
  public_subnets = {
    for name, subnet in var.subnets : name => subnet if subnet.public
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.key}"
    Tier = each.value.public ? "public" : "private"
  })
}

resource "aws_route_table" "public" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-public" })
}

resource "aws_route" "internet" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
  route_table_id         = aws_route_table.public[0].id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.this[each.key].id
}
