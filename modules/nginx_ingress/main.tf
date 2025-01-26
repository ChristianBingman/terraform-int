resource "helm_release" "nginx-ingress" {
  name = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = var.namespace
  create_namespace = true

  values = [
    <<-EOT
    controller:
      metrics:
        enabled: true
        service:
          annotations:
            prometheus.io/port: "10254"
            prometheus.io/scrape: "true"
        serviceMonitor:
          enabled: true
      allowSnippetAnnotations: true
      ingressClassResource:
        default: true
      service:
        type: "LoadBalancer"
        annotations:
          "metallb.universe.tf/loadBalancerIPs": ${var.metallb_ip}
          "metallb.universe.tf/ip-allocated-from-pool": "default-pool"
    EOT
  ]
}
