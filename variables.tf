variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "secondary_location" {
  description = "Azure region for the optional secondary deployment"
  type        = string
  default     = "eastus2"
}

variable "create_secondary_region" {
  description = "Set to true to create the secondary-region resources"
  type        = bool
  default     = false
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
}


variable "containers" {
  type = map(object({
    image  = string
    cpu    = number
    memory = number
    port   = number
  }))
}