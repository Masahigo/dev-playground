variable "subscription_id" {
  description = "Target Azure subscription ID"
  default     = "cff7ced3-00d8-477f-8589-11da069c1da1"
}

variable "location" {
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

variable "tags" {
  type        = map
  description = "Tags for resources"
  default = {
    "environment"  = "demo"
    "application"  = "SPA"
  }
}
