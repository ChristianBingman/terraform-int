resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "elasticsearch_cluster" {
  lifecycle {
    ignore_changes = [
      manifest.spec.nodeSets
    ]
  }
  manifest = {
    apiVersion = "elasticsearch.k8s.elastic.co/v1"
    kind = "Elasticsearch"
    metadata = {
      name = var.cluster_name
      namespace = var.namespace
    }
    spec = {
      version = "8.15.3"
      http = {
        service = {
          metadata = {
            annotations = {
              "metallb.io/loadBalancerIPs" = "10.2.0.40"
              "metallb.io/ip-allocated-from-pool" = "default-pool"
            }
          }
          spec = {
            type = "LoadBalancer"
          }
        }
        tls = {
          selfSignedCertificate = {
            disabled = true
          }
        }
      }
      nodeSets = [
        {
          name = "masters"
          count = 1
          config = {
            "node.roles" = [ "master" ]
            "path.repo" = [ "/usr/share/elasticsearch/data/snapshot" ]
          }
          podTemplate = {
              containers = [
                {
                  name = "elasticsearch-int-es-masters-0"
                  volumeMounts = [
                    {
                      mountPath = "/usr/share/elasticsearch/data/snapshot"
                      name = "snaphshots-shared"
                    }
                  ]
                }
              ]
            spec = {
              volumes = [
                {
                  name = "snapshots"
                  persistentVolumeClaim = {
                    claimName = "snapshots-shared"
                  }
                }
              ]
            }
          }
          volumeClaimTemplates = [
            {
              metadata = {
                name = "elasticsearch-data"
              }
              spec = {
                accessModes = [ "ReadWriteOnce" ]
                resources = {
                  requests = {
                    storage = "5Gi"
                  }
                }
              }
            }
          ]
        },
        {
          name = "data"
          count = 2
          config = {
            "node.roles" = [ "master", "data_content", "data_hot", "data_warm" ]
            "path.repo" = [ "/usr/share/elasticsearch/data/snapshot" ]
          }
          podTemplate = {
            spec = {
              containers = [
                {
                  name = "elasticsearch-int-es-data-0"
                  volumeMounts = [
                    {
                      mountPath = "/usr/share/elasticsearch/data/snapshot"
                      name = "snaphshots-shared"
                    }
                  ]
                },
                {
                  name = "elasticsearch-int-es-data-1"
                  volumeMounts = [
                    {
                      mountPath = "/usr/share/elasticsearch/data/snapshot"
                      name = "snaphshots-shared"
                    }
                  ]
                }
              ]
              volumes = [
                {
                  name = "snapshots"
                  persistentVolumeClaim = {
                    claimName = "snapshots-shared"
                  }
                }
              ]
            }
          }
          volumeClaimTemplates = [
            {
              metadata = {
                name = "elasticsearch-data"
              }
              spec = {
                accessModes = [ "ReadWriteOnce" ]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          ]
        },
        {
          name = "data-cold"
          count = 2
          config = {
            "node.roles" = [ "data_cold", "data_frozen" ]
            "path.repo" = [ "/usr/share/elasticsearch/data/snapshot" ]
          }
          podTemplate = {
            spec = {
              containers = [
                {
                  name = "elasticsearch-int-es-data-cold-0"
                  volumeMounts = [
                    {
                      mountPath = "/usr/share/elasticsearch/data/snapshot"
                      name = "snaphshots-shared"
                    }
                  ]
                },
                {
                  name = "elasticsearch-int-es-data-cold-1"
                  volumeMounts = [
                    {
                      mountPath = "/usr/share/elasticsearch/data/snapshot"
                      name = "snaphshots-shared"
                    }
                  ]
                }
              ]
              volumes = [
                {
                  name = "snapshots"
                  persistentVolumeClaim = {
                    claimName = "snapshots-shared"
                  }
                }
              ]
            }
          }
          volumeClaimTemplates = [
            {
              metadata = {
                name = "elasticsearch-data"
              }
              spec = {
                accessModes = [ "ReadWriteOnce" ]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
                storageClassName = "nfs-client"
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_persistent_volume_claim" "snapshots" {
  metadata {
    name      = "snapshots-shared"
    namespace = "elasticsearch-int"
  }

  spec {
    access_modes       = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_manifest" "kibana" {
  manifest = {
    apiVersion = "kibana.k8s.elastic.co/v1"
    kind = "Kibana"
    metadata = {
      name = "kibana-int"
      namespace = var.namespace
    }
    spec = {
      version = "8.15.3"
      count = 1
      elasticsearchRef = {
        name = var.cluster_name
      }
    }
  }
}
