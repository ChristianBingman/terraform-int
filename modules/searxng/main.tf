locals {
  app_name = "searxng"
  image = "searxng/searxng:2025.7.5-6ff4035"
  port = 8080
  secret_name = "searxng-http-tls"
  gluetun_image = "ghcr.io/qdm12/gluetun:v3.40.0"
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "${local.app_name}-ingress"
    namespace = var.namespace
    annotations = {
      "cert-manager.io/cluster-issuer" = "le-christianbingman-com"
      "nginx.ingress.kubernetes.io/auth-type" = "basic"
      "nginx.ingress.kubernetes.io/auth-secret" = "basic-auth"
      "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required"
    }
  }
  spec {
    ingress_class_name = "nginx"
    default_backend {
      service {
        name = "${local.app_name}-http"
        port {
          number = local.port
        }
      }
    }
    rule {
      host = "search.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "${local.app_name}-http"
              port {
                number = local.port
              }
            }
          }
          path_type = "Prefix"
          path = "/"
        }
      }
    }
    rule {
      host = "search.int.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "${local.app_name}-http"
              port {
                number = local.port
              }
            }
          }
          path_type = "Prefix"
          path = "/"
        }
      }
    }
    tls {
      secret_name = local.secret_name
      hosts = ["search.int.christianbingman.com", "search.christianbingman.com"]
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = "${local.app_name}-http"
    namespace = var.namespace
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = local.app_name
    }
    port {
      name = local.app_name
      port = local.port
      target_port = "http"
      protocol = "TCP"
    }
  }
}
resource "kubernetes_secret" "basic-auth-secret" {
  metadata {
    name = "basic-auth"
    namespace = var.namespace
  }
  data = {
    auth = var.basic_auth
  }
  type = "generic"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
    labels = {
      app = local.app_name
    }
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = local.app_name
    namespace = var.namespace
    labels = {
      app = local.app_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.app_name
        }
      }
      spec {
        container {
          name = "gluetun"
          image = local.gluetun_image
          image_pull_policy = "Always"
          resources {
            limits = {
              memory = "512Mi"
            }
            requests = {
              memory = "256Mi"
            }
          }
          port {
            name = "http"
            container_port = local.port
          }
          security_context {
            capabilities {
              add = [ "NET_ADMIN" ]
            }
          }
          liveness_probe {
            exec {
              command = [ "sh", "-c", "ping -c 1 www.google.com || exit 1" ]
            }
            period_seconds = 20
            timeout_seconds = 10
            failure_threshold = 5
          }
          env {
            name = "FIREWALL_OUTBOUND_SUBNETS"
            value = "10.0.0.0/16"
          }
          env {
            name = "TZ"
            value = "America/Chicago"
          }
          env {
            name = "VPN_SERVICE_PROVIDER"
            value = var.wireguard_provider
          }
          env {
            name = "VPN_TYPE"
            value = "wireguard"
          }
          env {
            name = "WIREGUARD_PRIVATE_KEY"
            value = var.wireguard_private_key
          }
          env {
            name = "WIREGUARD_ADDRESSES"
            value = var.wireguard_addresses
          }
          env {
            name = "WIREGUARD_PRESHARED_KEY"
            value = var.wireguard_preshared_key
          }
          env {
            name = "WIREGUARD_ENDPOINT_PORT"
            value = var.wireguard_endpoint_port
          }
          env {
            name = "SERVER_REGIONS"
            value = var.wireguard_server_region
          }
          env {
            name = "DNS_KEEP_NAMESERVER"
            value = "on"
          }
        }
        container {
          name = local.app_name
          image = local.image
          liveness_probe {
            http_get {
              path = "/healthz"
              port = local.port
            }
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = local.port
            }
          }
          env {
            name = "TZ"
            value = "America/Chicago"
          }
          env {
            name = "INSTANCE_NAME"
            value = "Christian's Searxng Instance"
          }
          env {
            name = "BASE_URL"
            value = "https://searxng.int.christianbingman.com"
          }
          env {
            name = "AUTOCOMPLETE"
            value = "false"
          }
        }
      }
    }
  }
}
