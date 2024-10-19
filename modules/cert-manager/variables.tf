variable "recursive_nameservers" {
  type = list(string)
  default = ["8.8.8.8:53", "1.1.1.1:53"]
}

variable "cloudflare_api_token" {
  type = string
}

variable "servicemonitor_enabled" {
  type = bool
  default = true
}
