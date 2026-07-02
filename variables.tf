variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "secondary_location" {
  type    = string
  default = "Westus"
}

variable "create_secondary_region" {
  description = "Set to true to create the secondary-region resource group"
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