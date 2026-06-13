variable "database_name" {
  type        = string
  description = "Application database name"
}

variable "app_username" {
  type        = string
  description = "Application user username"
}

variable "app_password" {
  type        = string
  sensitive   = true
  description = "Application user password"
}

variable "release_name" {
  type    = string
  default = "mongodb"
}

variable "namespace" {
  type    = string
  default = "mongodb"
}

variable "chart_version" {
  type    = string
  default = "17.0.1"
}

variable "root_username" {
  type    = string
  default = "admin"
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "storage_size" {
  type    = string
  default = "1Gi"
}

variable "service_type" {
  type    = string
  default = "ClusterIP"
}

variable "resources" {
  type = any
  default = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}
