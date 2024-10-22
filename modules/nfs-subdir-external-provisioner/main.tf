resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "nfs-dynamic-provisioner" {
  name = "nfs-dynamic-provisioner"
  repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  chart = "nfs-subdir-external-provisioner"
  namespace = var.namespace

  set {
    name = "nfs.path"
    value = "/export/Kubernetes"
  }

  set {
    name = "nfs.server"
    value = "ironman.christianbingman.com"
  }

  set {
    name = "storageClass.defaultClass"
    value = false
  }

  set {
    name = "storageClass.accessModes"
    value = "ReadWriteOnce"
  }
}
