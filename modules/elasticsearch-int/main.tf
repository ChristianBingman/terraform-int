resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "elasticsearch_cluster" {
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
              "metallb.universe.tf/loadBalancerIPs" = "10.2.0.40"
              "metallb.universe.tf/ip-allocated-from-pool" = "default-pool"
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
