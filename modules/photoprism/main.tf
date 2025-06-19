resource "kubernetes_namespace" "photoprism" {
  metadata {
    name = var.namespace
    labels = {
      app = var.selector
    }
  }
}

resource "kubernetes_stateful_set" "photoprism" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "photoprism"
    namespace = var.namespace
  }
  spec {
    selector {
      match_labels = {
        app = var.selector
      }
    }
    service_name = "photoprism"
    replicas = 1
    template {
      metadata {
        labels = {
          app = var.selector
        }
      }
      spec {
        container {
          name = "photoprism"
          image = "photoprism/photoprism:latest"
          env {
            name = "PHOTOPRISM_HTTP_HOST"
            value = "0.0.0.0"
          }
          env {
            name = "PHOTOPRISM_HTTP_PORT"
            value = 2342
          }
          port {
            container_port = 2342
            name = "http"
          }
          volume_mount {
            mount_path = "/photoprism/originals"
            name = "originals"
          }
          volume_mount {
            mount_path = "/photoprism/import"
            name = "import"
          }
          volume_mount {
            mount_path = "/photoprism/storage"
            name = "storage"
          }
          readiness_probe {
            http_get {
              path = "/api/v1/status"
              port = "http"
            }
          }
          resources {
            requests = {
              cpu = "500m"
              memory = "1Gi"
            }
            limits = {
              memory = "3Gi"
            }
          }
        }
        volume {
          name = "originals"
          persistent_volume_claim {
            claim_name = "originals"
          }
        }
        volume {
          name = "import"
          persistent_volume_claim {
            claim_name = "import"
          }
        }
        volume {
          name = "storage"
          persistent_volume_claim {
            claim_name = "storage"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "photoprism" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "photoprism-frontend"
    namespace = var.namespace
    annotations = {
      "metallb.universe.tf/ip-allocated-from-pool" = "default-pool"
    }
  }
  spec {
    port {
      name = "http"
      port = 80
      protocol = "TCP"
      target_port = "http"
    }
    selector = {
      app = var.selector
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_persistent_volume_claim" "storage" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "storage"
    namespace = var.namespace
  }
  spec {
    access_modes = [ "ReadWriteOnce" ]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}
resource "kubernetes_persistent_volume_claim" "import" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "import"
    namespace = var.namespace
  }
  spec {
    access_modes = [ "ReadWriteOnce" ]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}
resource "kubernetes_persistent_volume_claim" "originals" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "originals"
    namespace = var.namespace
  }
  spec {
    access_modes = [ "ReadWriteOnce" ]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_ingress_v1" "photoprism-dashboard" {
  depends_on = [kubernetes_namespace.photoprism]
  metadata {
    name = "photoprism-http"
    namespace = var.namespace
    annotations = {
      "cert-manager.io/cluster-issuer" = "le-christianbingman-com"
    }
  }
  spec {
    ingress_class_name = "nginx"
    default_backend {
      service {
        name = "photoprism-frontend"
        port {
          number = 80
        }
      }
    }
    rule {
      host = "photoprism.int.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "photoprism-frontend"
              port {
                number = 80
              }
            }
          }
          path_type = "Prefix"
          path = "/"
        }
      }
    }
    tls {
      secret_name = "photoprism-tls-secret"
      hosts = ["photoprism.int.christianbingman.com"]
    }
  }
}
