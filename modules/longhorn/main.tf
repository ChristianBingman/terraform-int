resource "helm_release" "longhorn" {
  name = "longhorn"
  repository = "https://charts.longhorn.io"
  chart = "longhorn"
  namespace = "longhorn"
  create_namespace = true
  version = "v1.7.2"
  set {
    name = "persistence.defaultClassReplicaCount"
    value = "2"
  }

  set {
    name = "defaultSettings.backupTarget"
    value = (var.smb_username == "" ? "" : var.backup_target)
  }

  set {
    name = "defaultSettings.backupTargetCredentialSecret"
    value = (var.smb_username == "" ? "" : "cifs-secret")
  }
  
  set {
    name = "metrics.serviceMonitor.enabled"
    value = "true"
  }
}

resource "kubernetes_secret" "cifs-secret" {
   metadata {
       name = "cifs-secret"
       namespace = "longhorn"
   }

   data = {
       CIFS_USERNAME = var.smb_username
       CIFS_PASSWORD = var.smb_password
   }

   type = "Opaque"
}
