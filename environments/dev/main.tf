locals {
  name = "portfolio-dev"
  tags = {
    Environment = "dev"
    Project     = "terraform-aws-lab"
    Owner       = "portfolio"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/app.py"
  output_path = "${path.module}/lambda.zip"
}

module "networking" {
  source = "../../modules/networking"

  name = local.name
  subnets = {
    public_a  = { cidr_block = "10.20.1.0/24", availability_zone = "us-west-2a", public = true }
    private_a = { cidr_block = "10.20.11.0/24", availability_zone = "us-west-2a" }
    private_b = { cidr_block = "10.20.12.0/24", availability_zone = "us-west-2b" }
  }
  tags = local.tags
}

module "serverless_api" {
  source = "../../modules/serverless-api"

  lambda_package_path = data.archive_file.lambda.output_path
  name                = local.name
  tags                = local.tags
}

output "api_endpoint" {
  description = "Development API endpoint."
  value       = module.serverless_api.api_endpoint
}

