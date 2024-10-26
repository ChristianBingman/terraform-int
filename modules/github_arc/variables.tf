variable "controller_namespace" {
  type = string
  default = "arc-controller"
}

variable "runner_namespace" {
  type = string
  default = "arc-runners"
}

variable "github_pat" {
  type = string
}
