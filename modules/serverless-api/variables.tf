variable "name" {
  description = "Name prefix for serverless resources."
  type        = string
}

variable "lambda_package_path" {
  description = "Path to a reviewed Lambda deployment zip created outside the module."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention period."
  type        = number
  default     = 30

  validation {
    condition     = contains([7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must use an AWS-supported portfolio value."
  }
}

variable "tags" {
  description = "Additional tags applied to supported resources."
  type        = map(string)
  default     = {}
}

