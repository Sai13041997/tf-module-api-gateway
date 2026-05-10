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

# --------------------------------------------------
# mTLS Custom Domain Outputs
# Used for SOAP API Gateway (Kentucky IVS integration)
# --------------------------------------------------

output "soap_domain_name" {
  description = "Custom domain name for the SOAP API Gateway."
  value       = var.mtls_enabled ? aws_api_gateway_domain_name.soap[0].domain_name : ""
}

output "soap_cloudfront_domain_name" {
  description = "CloudFront domain name for the SOAP API Gateway custom domain."
  value       = var.mtls_enabled ? aws_api_gateway_domain_name.soap[0].cloudfront_domain_name : ""
}
