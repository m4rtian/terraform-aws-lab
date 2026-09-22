mock_provider "aws" {}

run "creates_stably_keyed_subnets" {
  command = plan

  variables {
    name = "test"
    subnets = {
      private_a = { cidr_block = "10.20.11.0/24", availability_zone = "us-west-2a" }
      private_b = { cidr_block = "10.20.12.0/24", availability_zone = "us-west-2b" }
    }
  }

  assert {
    condition     = length(aws_subnet.this) == 2
    error_message = "The networking module must create every named subnet."
  }
}
