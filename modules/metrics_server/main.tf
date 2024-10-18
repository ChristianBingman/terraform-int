resource "helm_release" "metrics_server" {
  name       = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = var.namespace
  create_namespace = true

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
