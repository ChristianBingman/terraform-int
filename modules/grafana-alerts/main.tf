locals {
  alerts = fileset(path.module, "*.{yaml,yml}")
}

resource "kubernetes_config_map" "grafana-alerts" {
  for_each = { for f in local.alerts : f => f }
  metadata {
    name = each.key
    namespace = "prometheus-stack"
    labels = {
      grafana_alert = 1
    }
  }
  data = {
    "alert.yml" = file("${path.module}/${each.value}")
  }
}
