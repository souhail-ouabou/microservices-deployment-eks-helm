resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

# requirments for some add-ons (EFS CSI driver)
  enable_dns_support   = true 
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-main"
  }
}