data "aws_vpc" "default" {
  # If vpc_name is "default", look for the AWS default VPC. 
  # Otherwise, search for a VPC with a matching "Name" tag.
  default = var.vpc_name == "default" ? true : false

  dynamic "filter" {
    for_each = var.vpc_name == "default" ? [] : [1]
    content {
      name   = "tag:Name"
      values = [var.vpc_name]
    }
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

data "aws_subnet" "default" {
    id = data.aws_subnets.default.ids[0]
}