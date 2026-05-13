# Allow API Gateway to invoke the custom authorizer Lambda
resource "aws_lambda_permission" "allow_apigw_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jwt_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  # Any stage/any method for this REST API
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*"
}

# Allow API Gateway to invoke each backend Lambda integration target
resource "aws_lambda_permission" "allow_apigw_invoke_backend" {
  for_each = local.routes_by_key

  statement_id  = "AllowAPIGatewayInvoke-${replace(replace(each.key, " ", "_"), "/", "_")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"

  # REST API method ARN pattern:
  # arn:aws:execute-api:{region}:{account}:{api-id}/{stage}/{httpVerb}/{resourcePath}
  # Use wildcard stage; lock to method+path.
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/${each.value.method}${each.value.path}"
}
