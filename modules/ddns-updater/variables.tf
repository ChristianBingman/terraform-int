variable "cloudflare_api_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "namespace" {
  type    = string
  default = "ddns-updater"
}
