resource "helm_release" "cnpg" {
  name = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart = "cloudnative-pg"
  namespace = "cnpg-system"
  create_namespace = true

  set {
    name = "monitoring.podMonitorEnabled"
    value = true
  }

  set {
    name = "monitoring.grafanaDashboard.create"
    value = true
  }
}

resource "kubernetes_namespace" "pg-global" {
  metadata {
    name = "pg-global"
  }
}

#resource "kubernetes_manifest" "maybe-database" {
#  manifest = {
#    apiVersion = "postgresql.cnpg.io/v1"
#    kind = "Database"
#    metadata = {
#      name = "maybedb"
#      namespace = "pg-global"
#    }
#    spec = {
#      name = "maybedb"
#      owner = "maybe-user"
#      cluster = {
#        name = "default-cluster"
#      }
#    }
#  }
#}

resource "kubernetes_manifest" "maybe-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Cluster"
    metadata = {
      name = "default-cluster"
      namespace = "pg-global"
    }
    spec = {
      instances = 2
      storage = {
        size = "2Gi"
      }
      monitoring = {
        enablePodMonitor = true
      }
#      managed = {
#        roles = [
#        {
#          name = "maybe-user"
#          ensure = "present"
#          comment = "Maybe Finance Service User"
#          login = true
#          superuser = false
#          passwordSecret = {
#            name = "maybe-db-user-login"
#          }
#        }
#        ]
#      }
    }
  }
}

#resource "kubernetes_secret" "maybe-db-user-login" {
#  metadata {
#    name = "maybe-db-user-login"
#    namespace = "pg-global"
#    labels = {
#      "cnpg.io/reload" = true
#    }
#  }
#  data = {
#    username = var.maybe_user
#    password = var.maybe_user_pass
#  }
#  type = "kubernetes.io/basic-auth"
#}
