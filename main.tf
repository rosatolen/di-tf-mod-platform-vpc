resource "aws_vpc" "mod" {
  cidr_block           = "10.${var.cidr_reservation_start}.${var.cidr_reservation_offset}.0/${var.cidr_reservation_size}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"
  tags                 = "${merge(var.tags, map("Name", format("%s", var.name)), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

# nat subnets
resource "aws_subnet" "nat_subnet" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "10.${var.cidr_reservation_start}.${var.nat_subnet_start[count.index]}.0/${var.nat_subnet_size}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.azs)}"
  tags              = "${merge(var.tags, map("Name", format("subnet-%s-nat-%s", var.name, element(var.azs, count.index))), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${element(aws_eip.nateip.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  count         = "${length(var.azs) * lookup(map(var.enable_nat_gateway, 1), "true", 0)}"
  tags          = "${merge(var.tags,map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"

  depends_on = ["aws_internet_gateway.mod"]
}

resource "aws_eip" "nateip" {
  vpc   = "true"
  count = "${length(var.azs) * lookup(map(var.enable_nat_gateway, 1), "true", 0)}"
}

resource "aws_route_table" "nat" {
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]
  count            = "${length(var.azs)}"
  tags             = "${merge(var.tags, map("Name", format("%s-rt-nat-%s", var.name, element(var.azs, count.index))), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

resource "aws_route" "nat_gateway" {
  route_table_id         = "${element(aws_route_table.nat.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.natgw.*.id, count.index)}"
  count                  = "${length(var.azs) * lookup(map(var.enable_nat_gateway, 1), "true", 0)}"

  depends_on = ["aws_route_table.nat"]
}

resource "aws_route_table_association" "nat_subnet" {
  count          = "${length(var.azs)}"
  subnet_id      = "${element(aws_subnet.nat_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.nat.*.id, count.index)}"

  depends_on = ["aws_route_table.nat"]
}

# public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "10.${var.cidr_reservation_start}.${var.public_subnet_start[count.index]}.0/${var.public_subnet_size}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.azs)}"
  tags              = "${merge(var.tags, map("Name", format("subnet-%s-public-%s", var.name, element(var.azs, count.index))), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"

  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
}

resource "aws_internet_gateway" "mod" {
  vpc_id = "${aws_vpc.mod.id}"
  tags   = "${merge(var.tags, map("Name", format("%s-igw", var.name)), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

resource "aws_route_table" "public" {
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.public_propagating_vgws}"]
  tags             = "${merge(var.tags, map("Name", format("%s-rt-public", var.name)))}"
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.mod.id}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.azs)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# internal subnets
resource "aws_subnet" "internal_subnet" {
  vpc_id            = "${aws_vpc.mod.id}"
  cidr_block        = "10.${var.cidr_reservation_start}.${var.internal_subnet_start[count.index]}.0/${var.internal_subnet_size}"
  availability_zone = "${element(var.azs, count.index)}"
  count             = "${length(var.azs)}"
  tags              = "${merge(var.tags, map("Name", format("subnet-%s-internal-%s", var.name, element(var.azs, count.index))), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

resource "aws_route_table" "internal" {
  vpc_id           = "${aws_vpc.mod.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]
  count            = "${length(var.azs)}"
  tags             = "${merge(var.tags, map("Name", format("%s-rt-internal-%s", var.name, element(var.azs, count.index))), map(format("kubernetes.io/cluster/%s",var.k8_cluster_name),"shared"))}"
}

resource "aws_route_table_association" "internal" {
  count = "${length(var.azs)}"
  subnet_id = "${element(aws_subnet.internal_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internal.*.id, count.index)}"
}