resource "kubernetes_namespace" "maybe" {
  metadata {
    name = "maybe"
    labels = {
      app = "maybe"
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name = "maybe-redis"
    namespace = "maybe"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "redis"
    }
    port {
      name = "redis"
      port = 6379
      target_port = "redis"
      protocol = "TCP"
    }
  }
}

resource "kubernetes_service" "web" {
  metadata {
    name = "maybe-web"
    namespace = "maybe"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "maybe-web"
    }
    port {
      name = "maybe-web"
      port = 3000
      target_port = "maybe-web"
      protocol = "TCP"
    }
  }
}

resource "kubernetes_deployment" "maybe-worker" {
  metadata {
    name = "maybe-worker"
    namespace = "maybe"
    labels = {
      app = "maybe-worker"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "maybe-worker"
      }
    }
    template {
      metadata {
        labels = {
          app = "maybe-worker"
        }
      }
      spec {
        container {
          name = "maybe-worker"
          image = "ghcr.io/maybe-finance/maybe:latest"
          command = ["bundle", "exec", "sidekiq"]
          env_from {
            config_map_ref {
              name = "maybe-env"
            }
          }
          env_from {
            secret_ref {
              name = "maybe-secrets"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "maybe-web" {
  metadata {
    name = "maybe-web"
    namespace = "maybe"
    labels = {
      app = "maybe-web"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "maybe-web"
      }
    }
    template {
      metadata {
        labels = {
          app = "maybe-web"
        }
      }
      spec {
        container {
          name = "maybe-web"
          image = "ghcr.io/maybe-finance/maybe:latest"
          port {
            name = "maybe-web"
            container_port = 3000
          }
          volume_mount {
            name = "maybe-storage"
            mount_path = "/rails/storage"
          }
          env_from {
            config_map_ref {
              name = "maybe-env"
            }
          }
          env_from {
            secret_ref {
              name = "maybe-secrets"
            }
          }
        }
        volume {
          name = "maybe-storage"
          persistent_volume_claim {
            claim_name = "maybe-storage"
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
    namespace = "maybe"
    labels = {
      app = "redis"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          name = "redis"
          image = "redis:latest"
          port {
            name = "redis"
            container_port = 6379
          }
          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            failure_threshold = 1
            initial_delay_seconds = 10
            period_seconds = 10
          }
          volume_mount {
            name = "redis-storage"
            mount_path = "/data"
          }
        }
        volume {
          name = "redis-storage"
          persistent_volume_claim {
            claim_name = "redis-storage"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "redis-storage" {
  metadata {
    name = "redis-storage"
    namespace = "maybe"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "maybe-storage" {
  metadata {
    name = "maybe-storage"
    namespace = "maybe"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_config_map" "maybe-env" {
   metadata {
       name = "maybe-env"
       namespace = "maybe"
   }
   data = {
    SELF_HOSTED = true
    RAILS_FORCE_SSL = false
    RAILS_ASSUME_SSL = false
    DB_HOST = "default-cluster-rw.pg-global.svc.cluster.local"
    DB_PORT = 5432
    REDIS_URL = "redis://maybe-redis:6379/1"
   }
}

resource "kubernetes_secret" "maybe-secrets" {
   metadata {
       name = "maybe-secrets"
       namespace = "maybe"
   }
   data = {
       POSTGRES_USER = var.pg_user
       POSTGRES_PASSWORD = var.pg_pass
       POSTGRES_DB = var.pg_db
       SECRET_KEY_BASE = var.secret_key
   }

   type = "kubernetes.io/opaque"
}

resource "kubernetes_ingress_v1" "maybe-dashboard" {
  metadata {
    name = "maybe-http"
    namespace = "maybe"
    annotations = {
      "cert-manager.io/cluster-issuer" = "le-christianbingman-com"
    }
  }
  spec {
    ingress_class_name = "nginx"
    default_backend {
      service {
        name = "maybe-web"
        port {
          number = 3000
        }
      }
    }
    rule {
      host = "maybe.int.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "maybe-web"
              port {
                number = 3000
              }
            }
          }
          path_type = "Prefix"
          path = "/"
        }
      }
    }
    tls {
      secret_name = "maybe-tls-secret"
      hosts = ["maybe.int.christianbingman.com"]
    }
  }
}
