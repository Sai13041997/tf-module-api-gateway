output "rest_api_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "REST API id."
}

output "invoke_url" {
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.this.stage_name}"
  description = "Base invoke URL."
}

output "authorizer_lambda_arn" {
  value       = aws_lambda_function.jwt_authorizer.arn
  description = "ARN of the created Entra JWT authorizer Lambda (per API)."
}
