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

variable "frigate_tapo_cam_ip" {
  type = string
}

variable "frigate_tapo_cam_username" {
  type = string
}

variable "frigate_tapo_cam_password" {
  type = string
}

variable "mqtt_host" {
  type = string
  default = "mosquitto.christianbingman.com"
}

variable "mqtt_admin_user" {
  type = string
}

variable "mqtt_admin_pass" {
  type = string
}

variable "searxng_public_auth_htpasswd" {
  type = string
}
