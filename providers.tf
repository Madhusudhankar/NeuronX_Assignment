terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }
}
provider "azurerm" {
  features {}
}
# Secondary region Provider
provider "azurerm" {
  alias = "secondary"
  features {}
}