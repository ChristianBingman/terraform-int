resource "kubernetes_namespace" "registry" {
  metadata {
    name = var.namespace
    labels = {
      app = "registry"
    }
  }
}

resource "kubernetes_service" "registry-https" {
  metadata {
    name = "registry-https"
    namespace = var.namespace
    annotations = {
      "metallb.io/loadBalancerIPs" = "10.2.0.44"
      "metallb.io/ip-allocated-from-pool" = "default-pool"
    }
    labels = {
      app = "registry"
    }
  }
  spec {
    port {
      port = 443
      name = "registry-https"
    }
    selector = {
      app = "registry"
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_stateful_set" "registry" {
  metadata {
    name = "registry"
    namespace = var.namespace
    labels = {
      app = "registry"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "registry"
      }
    }
    service_name = "registry"
    replicas = 1
    template {
      metadata {
        labels = {
          app = "registry"
        }
      }
      spec {
        volume {
          name = "registry-https-vol"
          secret {
            secret_name = "registry-https"
          }
        }
        container {
          name = "registry"
          image = "docker.io/registry"
          resources {
            limits = {
              memory = "128Mi"
            }
            requests = {
              memory = "32Mi"
            }
          }
          env {
            name = "REGISTRY_HTTP_ADDR"
            value = "0.0.0.0:443"
          }
          env {
            name = "REGISTRY_HTTP_TLS_CERTIFICATE"
            value = "/opt/tls/tls.crt"
          }
          env {
            name = "REGISTRY_HTTP_TLS_KEY"
            value = "/opt/tls/tls.key"
          }
          port {
            container_port = 443
            name = "registry-https"
          }
          volume_mount {
            name = "data"
            mount_path = "/var/lib/registry"
          }
          volume_mount {
            name = "registry-https-vol"
            read_only = true
            mount_path = "/opt/tls"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = [ "ReadWriteOncePod" ]
        resources {
          requests = {
            storage = "2Gi"
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].volume_claim_template[0].metadata[0].namespace
    ]
  }
}

resource "kubernetes_manifest" "registry-https" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Certificate"
    "metadata" = {
      "name" = "registry-https"
      "namespace" = var.namespace
    }
    "spec" = {
      "secretName" = "registry-https"
      "dnsNames" = [
        "registry.int.christianbingman.com"
      ]
      "issuerRef" = {
        "name" = "le-christianbingman-com"
        "kind" = "ClusterIssuer"
      }
    }
  }
}
