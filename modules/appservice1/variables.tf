variable "name_prefix" {}
variable "location" {}
variable "resource_group_name" {}
variable "sku" {
  default = "B1"
}
variable "docker_image" {
  default = "nginx"
}
variable "docker_tag" {
  default = "latest"
}