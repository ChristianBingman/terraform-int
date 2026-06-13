variable "namespace" {
  description = "Kubernetes namespace for TubeArchivist"
  type        = string
  default     = "tubearchivist"
}

variable "ta_username" {
  description = "Initial TubeArchivist username"
  type        = string
  sensitive   = true
}

variable "ta_password" {
  description = "Initial TubeArchivist password"
  type        = string
  sensitive   = true
}

variable "elastic_password" {
  description = "Elasticsearch password"
  type        = string
  sensitive   = true
}

variable "timezone" {
  description = "Timezone for TubeArchivist"
  type        = string
  default     = "America/New_York"
}

variable "host_uid" {
  description = "Host UID for file permissions"
  type        = string
  default     = "1000"
}

variable "host_gid" {
  description = "Host GID for file permissions"
  type        = string
  default     = "1000"
}
