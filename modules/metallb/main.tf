resource "helm_release" "metallb" {
  name = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart = "metallb"
  namespace = "metallb"
  create_namespace = true
}

resource "kubernetes_manifest" "default-advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind = "L2Advertisement"
    metadata = {
      name = "default-advertisement"
      namespace = "metallb"
    }
  }
}

resource "kubernetes_manifest" "default-pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind = "IPAddressPool"
    metadata = {
      name = "default-pool"
      namespace = "metallb"
    }
    spec = {
      addresses = [
        "10.2.0.40-10.2.0.50"
      ]
    }
  }
}
