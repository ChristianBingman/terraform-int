variable "namespace" {
  type = string
  default = "searxng"
}

variable "basic_auth" {
  type = string
}

variable "wireguard_preshared_key" {
  type = string
}

variable "wireguard_addresses" {
  type = string
}

variable "wireguard_private_key" {
  type = string
}

variable "wireguard_provider" {
  type = string
}

variable "wireguard_endpoint_port" {
  type = number
}

variable "wireguard_server_region" {
  type = string
}
