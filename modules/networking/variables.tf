variable "name" {
  description = "Name prefix for networking resources."
  type        = string
}

variable "vpc_cidr_block" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "subnets" {
  description = "Named subnet definitions with stable keys."
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = optional(bool, false)
  }))
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

