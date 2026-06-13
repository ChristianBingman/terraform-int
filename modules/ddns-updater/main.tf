resource "kubernetes_namespace" "ddns-updater" {
  metadata {
    name = var.namespace
    labels = {
      app = "ddns-updater"
    }
  }
}

resource "kubernetes_secret" "ddns-updater-config" {
  metadata {
    name      = "ddns-updater-config"
    namespace = var.namespace
  }
  data = {
    "config.json" = jsonencode({
      settings = [
        {
          provider   = "cloudflare"
          zone_id    = var.cloudflare_zone_id
          domain     = "christianbingman.com"
          host       = "vpn"
          ip_version = "ipv4"
          ipv6_suffix = ""
          token      = var.cloudflare_api_key
          proxied    = false
        },
        {
          provider   = "cloudflare"
          zone_id    = var.cloudflare_zone_id
          domain     = "christianbingman.com"
          host       = "vpn"
          ip_version = "ipv6"
          ipv6_suffix = ""
          token      = var.cloudflare_api_key
          proxied    = false
        }
      ]
    })
  }
  type = "Opaque"
}

resource "kubernetes_deployment" "ddns-updater" {
  metadata {
    name      = "ddns-updater"
    namespace = var.namespace
    labels = {
      app = "ddns-updater"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ddns-updater"
      }
    }
    template {
      metadata {
        labels = {
          app = "ddns-updater"
        }
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
        }
        container {
          name  = "ddns-updater"
          image = "qmcgaw/ddns-updater:v2"
          resources {
            limits = {
              memory = "64Mi"
            }
            requests = {
              memory = "16Mi"
              cpu    = "10m"
            }
          }
          env {
            name  = "CONFIG"
            value = "/config/config.json"
          }
          env {
            name  = "PERIOD"
            value = "5m"
          }
          env {
            name  = "UPDATE_COOLDOWN_PERIOD"
            value = "5m"
          }
          env {
            name  = "PUBLICIP_FETCHERS"
            value = "all"
          }
          env {
            name  = "HTTP_TIMEOUT"
            value = "10s"
          }
          env {
            name  = "LISTENING_ADDRESS"
            value = ":8000"
          }
          port {
            name           = "http"
            container_port = 8000
          }
          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
        volume {
          name = "config"
          secret {
            secret_name = kubernetes_secret.ddns-updater-config.metadata[0].name
          }
        }
      }
    }
  }
}
