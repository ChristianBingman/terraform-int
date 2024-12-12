resource "kubernetes_namespace" "cloudflare-tunnel" {
  metadata {
    name = "cloudflare-tunnel"
    labels = {
      app = "cloudflared"
    }
  }
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name = "cloudflared"
    namespace = "cloudflare-tunnel"
    labels = {
      app = "cloudflared"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "cloudflared"
      }
    }
    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }
      spec {
        container {
          name = "cloudflared"
          image = "cloudflare/cloudflared:2024.6.0"
          args = [
            "tunnel",
            "--config",
            "/etc/cloudflared/config/config.yaml",
            "run"
          ]
          liveness_probe {
            http_get {
              path = "/ready"
              port = 2000
            }
            failure_threshold = 1
            initial_delay_seconds = 10
            period_seconds = 10
          }
          volume_mount {
            name = "config"
            mount_path = "/etc/cloudflared/config"
            read_only = true
          }
          volume_mount {
            name = "creds"
            mount_path = "/etc/cloudflared/creds"
            read_only = true
          }
        }
        volume {
          name = "creds"
          secret {
            secret_name = "tunnel-credentials"
          }
        }
        volume {
          name = "config"
          config_map {
            name = "cloudflared"
            items {
              key = "config.yaml"
              path = "config.yaml"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "cloudflared" {
  metadata {
    name = "cloudflared"
    namespace = "cloudflare-tunnel"
    labels = {
      app = "cloudflared"
    }
  }
  data = {
    "config.yaml" = <<-EOT
      # Name of the tunnel you want to run
      tunnel: kubernetes-prod
      credentials-file: /etc/cloudflared/creds/credentials.json
      # Serves the metrics server under /metrics and the readiness server under /ready
      metrics: 0.0.0.0:2000
      # Autoupdates applied in a k8s pod will be lost when the pod is removed or restarted, so
      # autoupdate doesn't make sense in Kubernetes. However, outside of Kubernetes, we strongly
      # recommend using autoupdate.
      no-autoupdate: true
      # The `ingress` block tells cloudflared which local service to route incoming
      # requests to. For more about ingress rules, see
      # https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/ingress
      #
      # Remember, these rules route traffic from cloudflared to a local service. To route traffic
      # from the internet to cloudflared, run `cloudflared tunnel route dns <tunnel> <hostname>`.
      # E.g. `cloudflared tunnel route dns example-tunnel tunnel.example.com`.
      ingress:
      # The first rule proxies traffic to the httpbin sample Service defined in app.yaml
      - hostname: search.christianbingman.com
        service: https://nginx-ingress-ingress-nginx-controller.nginx-ingress.svc.cluster.local:443
        originRequest:
          noTLSVerify: true
      # This rule matches any traffic which didn't match a previous rule, and responds with HTTP 404.
      - service: http_status:404
    EOT
  }
}

resource "kubernetes_secret" "tunnel-credentials" {
  metadata {
    name = "tunnel-credentials"
    namespace = "cloudflare-tunnel"
  }
  data = {
    "credentials.json" = var.credentials
  }
  type = "Opaque"
}
