variable "resource_group" {
  description = "Resource Group the resources will reside"
  type = string
  default = "WHO"
}

variable "ssh_key_name" {
  description = "Name of SSH Key hosted in Azure to place in VM"
  type = string
  default = "whosmart"
}

variable "subnet_name" {
  description = "Name of the subnet to attach instance to"
  type = string
}

variable "network_name" {
  description = "Name of the network the subnet belongs to"
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS Region to use"
}

variable "domain_name" {
  type        = string
  description = "AWS Route53 Domain Name"
}

variable "route53_zone_name" {
  description = "Name of zone to insert DNS record into"
  type        = string
}