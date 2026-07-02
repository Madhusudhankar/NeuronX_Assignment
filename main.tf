resource "random_string" "primary_suffix" {
  length  = 5
  lower   = true
  special = false
  upper   = false
}

resource "random_string" "secondary_suffix" {
  count   = var.create_secondary_region ? 1 : 0
  length  = 5
  lower   = true
  special = false
  upper   = false
}

locals {
  primary_suffix        = random_string.primary_suffix.result
  secondary_suffix      = var.create_secondary_region ? random_string.secondary_suffix[0].result : null
  primary_address_space = ["10.0.0.0/16"]
  primary_subnet_prefix = ["10.0.1.0/24"]
  secondary_address_space = ["10.1.0.0/16"]
  secondary_subnet_prefix = ["10.1.1.0/24"]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_resource_group" "secondary_rg" {
  count    = var.create_secondary_region ? 1 : 0
  provider = azurerm.secondary
  name     = "${var.prefix}-secondary-rg"
  location = var.secondary_location
}

# Primary network module
module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  vnet_name   = "${var.prefix}-vnet"
  subnet_name = "${var.prefix}-subnet"
  nsg_name    = "${var.prefix}-nsg"

  address_space = local.primary_address_space
  subnet_prefix = local.primary_subnet_prefix
}

# Optional secondary network module
module "network_secondary" {
  count = var.create_secondary_region ? 1 : 0

  providers = {
    azurerm = azurerm.secondary
  }

  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.secondary_rg[0].name
  location            = var.secondary_location

  vnet_name   = "${var.prefix}-secondary-vnet"
  subnet_name = "${var.prefix}-secondary-subnet"
  nsg_name    = "${var.prefix}-secondary-nsg"

  address_space = local.secondary_address_space
  subnet_prefix = local.secondary_subnet_prefix
}

module "appservice1" {
  source              = "./modules/appservice1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  name_prefix  = "${var.prefix}-${local.primary_suffix}"
  sku          = var.app_service_sku
  docker_image = "nginx"
  docker_tag   = "latest"
}

module "appservice1_secondary" {
  count = var.create_secondary_region ? 1 : 0

  providers = {
    azurerm = azurerm.secondary
  }

  source              = "./modules/appservice1"
  resource_group_name = azurerm_resource_group.secondary_rg[0].name
  location            = var.secondary_location

  name_prefix  = "${var.prefix}-${local.secondary_suffix}"
  sku          = var.app_service_sku
  docker_image = "nginx"
  docker_tag   = "latest"
}

# Primary storage account
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}${local.primary_suffix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Optional secondary storage account
resource "azurerm_storage_account" "secondary_sa" {
  count                    = var.create_secondary_region ? 1 : 0
  provider                 = azurerm.secondary
  name                     = "${var.prefix}${local.secondary_suffix}"
  resource_group_name      = azurerm_resource_group.secondary_rg[0].name
  location                 = var.secondary_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sc" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "secondary_sc" {
  count                 = var.create_secondary_region ? 1 : 0
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.secondary_sa[0].name
  container_access_type = "private"
}

resource "azurerm_container_group" "containers" {
  for_each = var.containers

  name                = "${each.key}-${local.primary_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_address_type = "Public"
  dns_name_label  = "${each.key}-${local.primary_suffix}"
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

  depends_on = [azurerm_storage_account.sa]
}

resource "azurerm_container_group" "secondary_containers" {
  for_each = var.create_secondary_region ? var.containers : {}

  provider            = azurerm.secondary
  name                = "${each.key}-${local.secondary_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.secondary_rg[0].name

  ip_address_type = "Public"
  dns_name_label  = "${each.key}-${local.secondary_suffix}"
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

  depends_on = [azurerm_storage_account.secondary_sa[0]]
}