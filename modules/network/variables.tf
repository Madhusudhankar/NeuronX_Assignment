variable "resource_group_name" {}
variable "location" {}
variable "vnet_name" {}
variable "subnet_name" {}
variable "nsg_name" {}

variable "address_space" {
  type = list(string)
}

variable "subnet_prefix" {
  type = list(string)
}