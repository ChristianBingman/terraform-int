resource "helm_release" "mongodb" {
  name       = var.release_name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true

  values = [
    yamlencode({
      architecture = "standalone"

      auth = {
        enabled = true

        rootUser     = var.root_username
        rootPassword = var.root_password

        usernames = [var.app_username]
        passwords = [var.app_password]
        databases = [var.database_name]
      }

      persistence = {
        enabled = true
        size    = var.storage_size
      }

      service = {
        type = var.service_type
        port = 27017
      }
    })
  ]
}
