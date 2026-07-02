/*
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "uniqueuxtfstate"
    container_name       = "neuranxstate"
    key                  = "terraform.tfstate"
  }
}
*/

# Need to run Terraform init to initialize the backend configuration and set up the remote state storage in Azure Blob Storage.