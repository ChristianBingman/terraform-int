# Namespace
resource "kubernetes_namespace" "tubearchivist" {
  metadata {
    name = var.namespace
  }
}

# PersistentVolumeClaims
resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "tubearchivist-media"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "nfs-client"

    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "cache" {
  metadata {
    name      = "tubearchivist-cache"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10737418240"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name      = "tubearchivist-redis"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
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

# Redis Deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "archivist-redis"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
    labels = {
      app = "archivist-redis"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "archivist-redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "archivist-redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:latest"

          resources {
            limits = {
              memory = "128Mi"
            }
            requests = {
              memory = "32Mi"
            }
          }

          port {
            container_port = 6379
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis.metadata[0].name
          }
        }
      }
    }
  }
}

# Redis Service
resource "kubernetes_service" "redis" {
  metadata {
    name      = "archivist-redis"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
  }

  spec {
    selector = {
      app = "archivist-redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}

# TubeArchivist Deployment
resource "kubernetes_deployment" "tubearchivist" {
  metadata {
    name      = "tubearchivist"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
    labels = {
      app = "tubearchivist"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tubearchivist"
      }
    }

    template {
      metadata {
        labels = {
          app = "tubearchivist"
        }
      }

      spec {
        container {
          name  = "tubearchivist"
          image = "bbilly1/tubearchivist:v0.5.10"

          resources {
            limits = {
              memory = "2Gi"
            }
            requests = {
              memory = "1Gi"
            }
          }
          port {
            container_port = 8000
          }

          env {
            name  = "TA_AUTO_UPDATE_YTDLP"
            value = "release"
          }

          env {
            name  = "ES_URL"
            value = "http://elasticsearch-int-es-http.elasticsearch-int.svc.cluster.local:9200"
          }

          env {
            name  = "REDIS_CON"
            value = "redis://archivist-redis:6379"
          }

          env {
            name  = "HOST_UID"
            value = var.host_uid
          }

          env {
            name  = "HOST_GID"
            value = var.host_gid
          }

          env {
            name  = "TA_HOST"
            value = "https://ta.int.christianbingman.com"
          }

          env {
            name  = "TA_USERNAME"
            value = var.ta_username
          }

          env {
            name  = "TA_PASSWORD"
            value = var.ta_password
          }

          env {
            name  = "ELASTIC_PASSWORD"
            value = var.elastic_password
          }

          env {
            name  = "TZ"
            value = var.timezone
          }

          volume_mount {
            name       = "media"
            mount_path = "/youtube"
          }

          volume_mount {
            name       = "cache"
            mount_path = "/cache"
          }

          liveness_probe {
            http_get {
              path = "/api/health/"
              port = 8000
              http_header {
                name = "Host"
                value = "ta.int.christianbingman.com"
              }
            }
            initial_delay_seconds = 30
            period_seconds        = 120
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/health/"
              port = 8000
              http_header {
                name = "Host"
                value = "ta.int.christianbingman.com"
              }
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 10
          }
        }

        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.media.metadata[0].name
          }
        }

        volume {
          name = "cache"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.cache.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.redis
  ]
}

# TubeArchivist Service
resource "kubernetes_service" "tubearchivist" {
  metadata {
    name      = "tubearchivist"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
  }

  spec {
    selector = {
      app = "tubearchivist"
    }

    port {
      port        = 8000
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

# Ingress
resource "kubernetes_ingress_v1" "tubearchivist" {
  metadata {
    name      = "tubearchivist"
    namespace = kubernetes_namespace.tubearchivist.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "cert-manager.io/cluster-issuer"             = "le-christianbingman-com"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
    }
  }

  spec {
    tls {
      hosts = ["ta.int.christianbingman.com"]
      secret_name = "tubearchivist-tls"
    }

    rule {
      host = "ta.int.christianbingman.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.tubearchivist.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}

# Outputs
output "namespace" {
  description = "Namespace where TubeArchivist is deployed"
  value       = kubernetes_namespace.tubearchivist.metadata[0].name
}

output "ingress_url" {
  description = "URL to access TubeArchivist"
  value       = "https://ta.int.christianbingman.com"
}

output "service_name" {
  description = "TubeArchivist service name"
  value       = kubernetes_service.tubearchivist.metadata[0].name
}
