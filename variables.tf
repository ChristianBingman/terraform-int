variable "prometheus-stack_grafana_admin_password" {
  type = string
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

variable "cert-manager_cloudflare_api_token" {
  type = string
}

variable "cloudflare-tunnel_credentials" {
  type = string
}

variable "github_pat" {
  type = string
}

variable "github_client_id" {
  type = string
}

variable "github_client_secret" {
  type = string
}

variable "drone_rpc_secret" {
  type = string
}

variable "longhorn_smb_username" {
  type = string
}

variable "longhorn_smb_password" {
  type = string
}

variable "mosquitto_admin_login" {
  type = string
}
