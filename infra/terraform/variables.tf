variable "subscription_id" {
  type        = string
  description = "Target Azure subscription ID"
  default     = "cff7ced3-00d8-477f-8589-11da069c1da1"
}

variable "client_secret" { type = string }
variable "client_id" { type = string }
variable "tenant_id" { type = string }

variable "location" {
  type        = string
  description = "Location to deploy"
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Target resource group name"
  default     = "spa-demo-we-rg"
}

variable "common_resource_group_name" {
  type        = string
  description = "Common resource group name"
  default     = "common-we-rg"
}

variable "dns_zone_name" {
  type        = string
  description = "Name of a pre-created Azure DNS Zone for custom records."
  default     = "dev.msdevopsdude.com"
}

variable "linkedin_client_secret" {
  type        = string
  description = "LinkedIn App's client secret."
}

variable "tags" {
  type        = map
  description = "Tags for resources"
  default = {
    "environment" = "demo"
    "application" = "SPA"
  }
}
