resource "helm_release" "longhorn" {
  name = "longhorn"
  repository = "https://charts.longhorn.io"
  chart = "longhorn"
  namespace = "longhorn"
  create_namespace = true
  version = "v1.7.2"
  set {
    name = "persistence.defaultClassReplicaCount"
    value = "2"
  }

  set {
    name = "defaultSettings.backupTarget"
    value = (var.smb_username == "" ? "" : var.backup_target)
  }

  set {
    name = "defaultSettings.backupTargetCredentialSecret"
    value = (var.smb_username == "" ? "" : "cifs-secret")
  }
  
  set {
    name = "metrics.serviceMonitor.enabled"
    value = "true"
  }
}

resource "kubernetes_secret" "cifs-secret" {
   metadata {
       name = "cifs-secret"
       namespace = "longhorn"
   }

   data = {
       CIFS_USERNAME = var.smb_username
       CIFS_PASSWORD = var.smb_password
   }

   type = "Opaque"
}

resource "kubernetes_ingress_v1" "longhorn-dashboard" {
  metadata {
    name = "longhorn-dashboard"
    namespace = "longhorn"
    annotations = {
      "cert-manager.io/cluster-issuer" = "le-christianbingman-com"
      # This should be the in-cluster DNS name for the authentik outpost service
      # as when the external URL is specified here, nginx will overwrite some crucial headers
      "nginx.ingress.kubernetes.io/auth-url" = "http://ak-outpost-nginx-ingress.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx"
      # If you're using domain-level auth, use the authentication URL instead of the application URL
      "nginx.ingress.kubernetes.io/auth-signin" = "https://longhorn.int.christianbingman.com/outpost.goauthentik.io/start?rd=$scheme://$http_host$escaped_request_uri"
      "nginx.ingress.kubernetes.io/auth-response-headers" = "Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-entitlements,X-authentik-email,X-authentik-name,X-authentik-uid"
      "nginx.ingress.kubernetes.io/auth-snippet" = "proxy_set_header X-Forwarded-Host $http_host;"
    }
  }
  spec {
    ingress_class_name = "nginx"
    default_backend {
      service {
        name = "longhorn-frontend"
        port {
          number = 80
        }
      }
    }
    rule {
      host = "longhorn.int.christianbingman.com"
      http {
        path {
          backend {
            service {
              name = "ak-outpost-nginx-ingress"
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
              name = "longhorn-frontend"
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
      secret_name = "longhorn-ui-secret"
      hosts = ["longhorn.int.christianbingman.com"]
    }
  }
}

resource "kubernetes_manifest" "trim-job" {
  manifest = {
    apiVersion = "longhorn.io/v1beta2"
    kind = "RecurringJob"
    metadata = {
      name = "fs-trim"
      namespace = "longhorn"
    }
    spec = {
      concurrency = 1
      cron = "0 1 * * *"
      groups = ["default"]
      name = "fs-trim"
      retain = 0
      task = "filesystem-trim"
    }
  }
}
