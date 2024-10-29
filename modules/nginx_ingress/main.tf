resource "helm_release" "nginx-ingress" {
  name = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = var.namespace
  create_namespace = true

  values = [
    <<-EOT
    controller:
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
