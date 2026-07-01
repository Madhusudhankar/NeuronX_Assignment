resource "azurerm_service_plan" "plan" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = var.sku

}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = false
    application_stack {


      # Combine image and tag into the single required argument
      docker_image_name = "${var.docker_image}:${var.docker_tag}"

    }

  }
}