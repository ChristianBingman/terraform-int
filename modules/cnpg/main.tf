resource "helm_release" "cnpg" {
  name = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart = "cloudnative-pg"
  namespace = "cnpg-system"
  create_namespace = true
  version = "v0.27.1"

  set {
    name = "monitoring.podMonitorEnabled"
    value = true
  }

  set {
    name = "monitoring.grafanaDashboard.create"
    value = true
  }
  set {
    name = "resources.limits.memory"
    value = "128Mi"
  }
  set {
    name = "resources.requests.memory"
    value = "64Mi"
  }
}

resource "kubernetes_namespace" "pg-global" {
  metadata {
    name = "pg-global"
  }
}

resource "kubernetes_manifest" "privatebalance-dev-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Database"
    metadata = {
      name = "privatebalance-dev"
      namespace = "pg-global"
    }
    spec = {
      name = "privatebalance-dev"
      owner = "privatebalance"
      cluster = {
        name = "default-cluster"
      }
    }
  }
}

resource "kubernetes_manifest" "authentik-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Database"
    metadata = {
      name = "authentik"
      namespace = "pg-global"
    }
    spec = {
      name = "authentik"
      owner = "authentik"
      cluster = {
        name = "default-cluster"
      }
    }
  }
}

resource "kubernetes_manifest" "immich-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Database"
    metadata = {
      name = "immich"
      namespace = "pg-global"
    }
    spec = {
      name = "immich"
      owner = "immich"
      cluster = {
        name = "default-cluster"
      }
    }
  }
}

resource "kubernetes_manifest" "maybe-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Cluster"
    metadata = {
      name = "default-cluster"
      namespace = "pg-global"
    }
    spec = {
      resources = {
        limits = {
          memory = "512Mi"
        }
        requests = {
          memory = "128Mi"
        }
      }
      instances = 2
      storage = {
        size = "5Gi"
      }
      monitoring = {
        enablePodMonitor = true
      }
      managed = {
        roles = [
          {
            name = "authentik"
            ensure = "present"
            comment = "authentik user"
            login = true
            superuser = false
            passwordSecret = {
              name = "authentik-user-login"
            }
          },
          {
            name = "immich"
            ensure = "present"
            comment = "immich user"
            login = true
            superuser = false
            passwordSecret = {
              name = "immich-user-login"
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "default-db-pooler" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Pooler"
    metadata = {
      name = "pooler-rw"
      namespace = "pg-global"
    }
    spec = {
      template = {
        spec = {
          containers = [
            {
              name = "pgbouncer"
              resources = {
                limits = {
                  memory = "64Mi"
                }
                requests = {
                  memory = "16Mi"
                }
              }
            }
          ]
        }
      }
      cluster = {
        name = "default-cluster"
      }
      serviceTemplate = {
        metadata = {
          annotations = {
            "metallb.io/ip-allocated-from-pool" = "default-pool"
          }
        }
        spec = {
          type = "LoadBalancer"
        }
      }
      instances = 1
      type = "rw"
      pgbouncer = {
        poolMode = "session"
        parameters = {
          max_client_conn = "1000"
          default_pool_size = "10"
        }
      }
    }
  }
}

resource "kubernetes_secret" "authentik-user-login" {
  metadata {
    name = "authentik-user-login"
    namespace = "pg-global"
    labels = {
      "cnpg.io/reload" = true
    }
  }
  data = {
    username = var.authentik_user
    password = var.authentik_user_pass
  }
  type = "kubernetes.io/basic-auth"
}

