resource "helm_release" "eck-operator" {
  name = "my-eck-operator"
  repository = "https://helm.elastic.co"
  chart = "eck-operator"
  namespace = var.namespace
  create_namespace = true
  version = "2.13.0"
}
