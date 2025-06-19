resource "kubernetes_namespace" "timetagger" {
  metadata {
    name = "timetagger"
    labels = {
      app = "timetagger"
    }
  }
}

resource "kubernetes_service" "web" {
  metadata {
    name = "timetagger-http"
    namespace = "timetagger"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "timetagger"
    }
    port {
      name = "timetagger-http"
      port = 80
      target_port = "timetagger-http"
      protocol = "TCP"
    }
  }
}

resource "kubernetes_service" "authentik-externalname" {
  metadata {
    name = "ak-outpost-timetagger-ingress"
    namespace = "timetagger"
  }
  spec {
    type = "ExternalName"
    external_name = "ak-outpost-timetagger-ingress.authentik.svc.cluster.local"
  }
}

resource "kubernetes_deployment" "timetagger-web" {
  metadata {
    name = "timetagger-web"
    namespace = "timetagger"
    labels = {
      app = "timetagger"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "timetagger"
      }
    }
    template {
      metadata {
        labels = {
          app = "timetagger"
        }
      }
      spec {
        container {
          name = "timetagger-web"
          image = "ghcr.io/almarklein/timetagger:latest"
          port {
            name = "timetagger-http"
            container_port = 80
          }
          volume_mount {
            name = "timetagger-storage"
            mount_path = "/root/_timetagger"
          }
          env {
            name = "TIMETAGGER_PROXY_AUTH_ENABLED"
            value = true
          }
          env {
            name = "TIMETAGGER_PROXY_AUTH_TRUSTED"
            value = "0.0.0.0/0"
          }
          env {
            name = "TIMETAGGER_PROXY_AUTH_HEADER"
            value = "X-authentik-username"
          }
          env {
            name = "TIMETAGGER_BIND"
            value = "0.0.0.0:80"
          }
          env {
            name = "TIMETAGGER_DATADIR"
            value = "/root/_timetagger"
          }
          env {
            name = "TIMETAGGER_LOG_LEVEL"
            value = "debug"
          }
          env_from {
            secret_ref {
              name = "timetagger-secrets"
            }
          }
        }
        volume {
          name = "timetagger-storage"
          persistent_volume_claim {
            claim_name = "timetagger-storage"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "timetagger-storage" {
  metadata {
    name = "timetagger-storage"
    namespace = "timetagger"
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

resource "kubernetes_secret" "timetagger-secrets" {
   metadata {
       name = "timetagger-secrets"
       namespace = "timetagger"
   }
   data = {
       TIMETAGGER_CREDENTIALS = "test:$2a$08$n8fdaGs/vl3G2CCiFb6LB.pfP2atRQIetv8jEYcUM0YFHuVMWwIB2"
   }

   type = "kubernetes.io/opaque"
}

resource "kubernetes_ingress_v1" "timetagger-web" {
  metadata {
    name = "timetagger-http"
    namespace = "timetagger"
    annotations = {
      "cert-manager.io/cluster-issuer" = "le-christianbingman-com"
      # This should be the in-cluster DNS name for the authentik outpost service
      # as when the external URL is specified here, nginx will overwrite some crucial headers
      "nginx.ingress.kubernetes.io/auth-url" = "http://ak-outpost-timetagger-ingress.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx"
      # If you're using domain-level auth, use the authentication URL instead of the application URL
      "nginx.ingress.kubernetes.io/auth-signin" = "https://time.int.christianbingman.com/outpost.goauthentik.io/start?rd=$scheme://$http_host$escaped_request_uri"
      "nginx.ingress.kubernetes.io/auth-response-headers" = "Set-Cookie,X-authentik-username"
      "nginx.ingress.kubernetes.io/auth-snippet" = "proxy_set_header X-Forwarded-Host $http_host;"
    }
  }
  spec {
    ingress_class_name = "nginx"
    default_backend {
      service {
        name = "timetagger-http"
        port {
          number = 80
        }
      }
    }
    rule {
      host = "time.int.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "ak-outpost-timetagger-ingress"
              port {
                number = 9000
              }
            }
          }
          path_type = "Prefix"
          path = "/outpost.goauthentik.io"
        }
        path {
          backend {
            service {
              name = "timetagger-http"
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
      secret_name = "timetagger-tls-secret"
      hosts = ["time.int.christianbingman.com"]
    }
  }
}
