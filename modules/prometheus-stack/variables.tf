variable "admin_password" {
  type = string
  default = "prom-operator"
}

variable "smtp_host" {
  type = string
}

variable "smtp_user" {
  type = string
}

variable "smtp_pass" {
  type = string
}

variable "smtp_from_address" {
  type = string
  default = "admin@christianbingman.com"
}

variable "smtp_from_name" {
  type = string
  default = "Grafana Alerts"
}

variable "oidc_client_id" {
  type = string
}

variable "oidc_client_secret" {
  type = string
}
