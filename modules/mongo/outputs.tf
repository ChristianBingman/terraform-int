locals {
  service_name = "${var.release_name}-mongodb"
  fqdn         = "${local.service_name}.${var.namespace}.svc.cluster.local"
}

output "mongodb_release_name" {
  value = helm_release.mongodb.name
}

output "mongodb_namespace" {
  value = helm_release.mongodb.namespace
}

output "mongodb_host" {
  value = local.fqdn
}
