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
