output "primary_container_urls" {
  value = {
    for k, v in azurerm_container_group.containers :
    k => v.fqdn
  }
}

output "secondary_container_urls" {
  value = var.create_secondary_region ? {
    for k, v in azurerm_container_group.secondary_containers :
    k => v.fqdn
  } : {}
}

output "primary_subnet_id" {
  value = module.network.subnet_id
}

output "secondary_subnet_id" {
  value = var.create_secondary_region ? module.network_secondary[0].subnet_id : null
}

output "primary_app_service_url" {
  value = module.appservice1.app_url
}

output "secondary_app_service_url" {
  value = var.create_secondary_region ? module.appservice1_secondary[0].app_url : null
}
