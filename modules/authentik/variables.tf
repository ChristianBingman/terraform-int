variable "namespace" {
  type = string
  default = "authentik"
}

variable "pg_pass" {
  type = string
}

variable "authentik_secret" {
  type = string
}
