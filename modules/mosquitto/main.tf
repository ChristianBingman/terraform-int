resource "helm_release" "mosquitto" {
  name = "mosquitto"
  repository = "https://storage.googleapis.com/t3n-helm-charts"
  chart = "mosquitto"
  namespace = var.namespace
  create_namespace = true

  values = [
    <<-EOT
    authentication:
      passwordEntries: |-
        ${var.admin_login}
    service:
      type: LoadBalancer
      annotations:
        "metallb.universe.tf/loadBalancerIPs": "10.2.0.43"
        "metallb.universe.tf/ip-allocated-from-pool": "default-pool"
    EOT
  ]
}
