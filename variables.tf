variable "name" {
  type        = string
  description = "API name."
}

variable "stage_name" {
  type        = string
  description = "Stage name for the REST API. REST APIs require a stage."
  default     = "default"
}

variable "is_production" {
  type        = bool
  description = "If true, apply the production IP whitelist; otherwise apply the non-production whitelist."
}

variable "jwt_audience" {
  type        = list(string)
  description = "Accepted JWT audiences."
  default     = ["api://585f3a95-8bf5-4df4-b80b-585ca5ca2071"]
}

variable "routes" {
  description = <<EOT
Minimal backend lambda route definitions.
Example:
[
  { path = "/health", method = "GET",  lambda_arn = "arn:aws:lambda:..." },
  { path = "/users",  method = "POST", lambda_arn = "arn:aws:lambda:..." }
]
EOT

  type = list(object({
    path       = string
    method     = string
    lambda_arn = string
  }))
}

# --------------------------------------------------
# mTLS and Custom Domain Configuration
# Used for SOAP API Gateway (Kentucky IVS integration)
# --------------------------------------------------

variable "mtls_enabled" {
  type        = bool
  description = "Enable mTLS for the API Gateway."
  default     = false
}

variable "truststore_uri" {
  type        = string
  description = "S3 URI for the mTLS truststore PEM file."
  default     = ""
}

variable "custom_domain_name" {
  type        = string
  description = "Custom domain name for the API Gateway."
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for the custom domain."
  default     = ""
}
