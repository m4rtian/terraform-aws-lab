locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

resource "aws_dynamodb_table" "items" {
  name         = "${var.name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query"]
    effect  = "Allow"
    resources = [
      aws_dynamodb_table.items.arn,
      "${aws_dynamodb_table.items.arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}-data-access"
  policy = data.aws_iam_policy_document.lambda.json
  role   = aws_iam_role.lambda.id
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_lambda_function" "api" {
  filename         = var.lambda_package_path
  function_name    = var.name
  handler          = "app.handler"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  source_code_hash = filebase64sha256(var.lambda_package_path)
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags       = local.common_tags
  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  tags          = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  auto_deploy = true
  name        = "$default"

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 20
    throttling_rate_limit    = 10
  }

  tags = local.common_tags
}

resource "aws_lambda_permission" "api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
  statement_id  = "AllowApiGateway"
}

