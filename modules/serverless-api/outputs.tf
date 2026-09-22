output "api_endpoint" {
  description = "Base endpoint of the HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "table_name" {
  description = "DynamoDB table name used by the Lambda function."
  value       = aws_dynamodb_table.items.name
}

