# Find your default VPC
resource "aws_default_vpc" "default" {}

# Find the existing Internet Gateway
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

# Use the default subnet in us-east-1a
resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}

# Ensure the Route Table points to the Internet Gateway
resource "aws_route_table" "arca_rt" {
  vpc_id = aws_default_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_default_subnet.default_az1.id
  route_table_id = aws_route_table.arca_rt.id
}