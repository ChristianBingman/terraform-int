resource "helm_release" "authentik" {
  name = "authentik"
  repository = "https://charts.goauthentik.io"
  chart = "authentik"
  version = "2026.2.1"
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
        host: default-cluster-rw.pg-global.svc.cluster.local
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
      resources:
        limits:
          memory: 1Gi
        requests:
          memory: 512Mi
      metrics:
        enabled: true
        serviceMonitor:
          enabled: true

    worker:
      env:
      - name: "AUTHENTIK_WORKER__THREADS"
        value: "4"
      resources:
        limits:
          memory: 3Gi
        requests:
          memory: 2Gi
      metrics:
        enabled: true
        serviceMonitor:
          enabled: true

    prometheus:
      rules:
        enabled: true
    EOT
  ]
}
