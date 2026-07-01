output "container_urls" {
  value = {
    for k, v in azurerm_container_group.containers :
    k => v.fqdn
  }
}

output "subnet_id" {
  value = module.network.subnet_id
}

output "app_service_url" {
  value = module.appservice1.app_url
}
