resource "helm_release" "cert-manager" {
  name = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  namespace = "cert-manager"
  create_namespace = true
  version = "v1.15.0"

  set {
    name = "crds.enabled"
    value = true
  }

  set_list {
    name = "extraArgs"
    value = [
      "--dns01-recursive-nameservers-only",
      "--dns01-recursive-nameservers=${join(",", var.recursive_nameservers)}"
    ]
  }

  set {
    name = "prometheus.enabled"
    value = var.servicemonitor_enabled
  }

  set {
    name = "prometheus.servicemonitor.enabled"
    value = var.servicemonitor_enabled
  }

  set {
    name = "ingressShim.defaultIssuerName"
    value = "le-christianbingman-com"
  }

  set {
    name = "ingressShim.defaultIssuerKind"
    value = "ClusterIssuer"
  }
}

resource "kubernetes_manifest" "le-christianbingman-com" {
  depends_on = [helm_release.cert-manager]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "le-christianbingman-com"
    }
    "spec" = {
      "acme" = {
        "email" = "christianbingman@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "dns01" = {
              "cloudflare" = {
                "apiTokenSecretRef" = {
                  "key" = "apiToken"
                  "name" = "cloudflare-api-token-secret"
                }
              }
            }
          },
        ]
      }
    }
  }
}

resource "kubernetes_secret" "cloudflare-api-token-secret" {
  metadata {
    name = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }
  data = {
    apiToken = var.cloudflare_api_token
  }
  type = "Opaque"
}
