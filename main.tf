resource "random_string" "suffix" {
  length  = 5
  lower   = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Network module
module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  vnet_name   = "${var.prefix}-vnet"
  subnet_name = "${var.prefix}-subnet"
  nsg_name    = "${var.prefix}-nsg"

  address_space = ["10.0.0.0/16"]
  subnet_prefix = ["10.0.1.0/24"]
}

module "appservice1" {
  source              = "./modules/appservice1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  name_prefix  = "${var.prefix}-${random_string.suffix.result}"
  sku          = var.app_service_sku
  docker_image = "nginx"
  docker_tag   = "latest"
}
# Storage

resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

##   Storage Account

resource "azurerm_storage_container" "sc" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

##
# Multi-Container Deployment
resource "azurerm_container_group" "containers" {
  for_each = var.containers

  name                = "${each.key}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_address_type = "Public"
  dns_name_label  = "${each.key}-${random_string.suffix.result}"
  os_type         = "Linux"

  container {
    name   = each.key
    image  = each.value.image
    cpu    = each.value.cpu
    memory = each.value.memory

    ports {
      port     = each.value.port
      protocol = "TCP"
    }
  }
  depends_on = [
    azurerm_storage_account.sa
  ]

}

# Secondary region example
resource "azurerm_resource_group" "secondary_rg" {
  provider = azurerm.secondary
  name     = "${var.prefix}-secondary-rg"
  location = var.secondary_location
}