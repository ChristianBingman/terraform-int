resource "helm_release" "authentik" {
  name = "authentik"
  repository = "https://charts.goauthentik.io"
  chart = "authentik"
  namespace = var.namespace
  create_namespace = true
  values = [
    <<-EOT
    authentik:
      secret_key: ${var.authentik_secret}
      # This sends anonymous usage-data, stack traces on errors and
      # performance data to authentik.error-reporting.a7k.io, and is fully opt-in
      error_reporting:
        enabled: false
      postgresql:
        password: ${var.pg_pass}

    server:
      ingress:
        enabled: true
        annotations:
          cert-manager.io/cluster-issuer: "le-christianbingman-com"
        hosts:
          - auth.christianbingman.com
        tls:
          - secretName: authentik-https
            hosts:
              - auth.christianbingman.com

    postgresql:
      enabled: true
      auth:
        password: ${var.pg_pass}

    redis:
      enabled: true
    EOT
  ]
}
