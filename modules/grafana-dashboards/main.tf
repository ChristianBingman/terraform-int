locals {
  alerts = fileset(path.module, "*.{json}")
}

resource "kubernetes_config_map" "grafana-dashboards" {
  for_each = { for f in local.alerts : f => f }
  metadata {
    name = each.key
    namespace = "prometheus-stack"
    labels = {
      grafana_dashboard = 1
    }
  }
  data = {
    "dashboard.json" = file("${path.module}/${each.value}")
  }
}
