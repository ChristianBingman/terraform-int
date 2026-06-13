resource "helm_release" "immich" {
  name = "immich"
  repository = "oci://ghcr.io/immich-app/immich-charts"
  chart = "immich"
  namespace = var.namespace
  create_namespace = true

  values = [
    <<-EOT
controllers:
  main:
    containers:
      main:
        resources:
          limits:
            memory: 5Gi
          requests:
            memory: 3Gi
        image:
          tag: v2.6.1
        env:
          REDIS_HOSTNAME: '{{ printf "%s-valkey" .Release.Name }}'
          IMMICH_MACHINE_LEARNING_URL: 'x23.christianbingman.com:3003'
          DB_HOSTNAME: immich-cluster-rw
          DB_USERNAME: "${var.immich_user}"
          DB_PASSWORD: "${var.immich_user_pass}"

immich:
  metrics:
    # Enabling this will create the service monitors needed to monitor immich with the prometheus operator
    enabled: true
  persistence:
    # Main data store for all photos shared between different components.
    library:
      # Automatically creating the library volume is not supported by this chart
      # You have to specify an existing PVC to use
      existingClaim: immich-library
  # configuration is immich-config.json converted to yaml
  # ref: https://immich.app/docs/install/config-file/
  #
  configuration: {}
    # trash:
    #   enabled: false
    #   days: 30
    # storageTemplate:
    #   enabled: true
    #   template: "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}"
  # Sets the resource Kind to store configuration in. Must be either ConfigMap or Secret.
  configurationKind: ConfigMap

# Dependencies

valkey:
  enabled: true
  controllers:
    main:
      containers:
        main:
          resources:
            limits:
              memory: 64Mi
            requests:
              memory: 32Mi
          image:
            repository: docker.io/valkey/valkey
            tag: 9.0-alpine@sha256:1be494495248d53e3558b198a1c704e6b559d5e99fe4c926e14a8ad24d76c6fa
            pullPolicy: IfNotPresent
  persistence:
    data:
      enabled: true
      size: 512Mi
      # Optional: Set this to persistentVolumeClaim to keep job queues persistent
      type: persistentVolumeClaim
      accessMode: ReadWriteOnce

# Immich components

server:
  enabled: true
  controllers:
    main:
      containers:
        main:
          image:
            repository: ghcr.io/immich-app/immich-server
            pullPolicy: IfNotPresent
  ingress:
    main:
      enabled: true
      annotations:
        # proxy-body-size is set to 0 to remove the body limit on file uploads
        nginx.ingress.kubernetes.io/proxy-body-size: "0"
        "cert-manager.io/cluster-issuer": "le-christianbingman-com"
      hosts:
        - host: immich.int.christianbingman.com
          paths:
            - path: "/"
              service:
                identifier: main
      tls:
      - hosts:
        - immich.int.christianbingman.com
        secretName: immich-tls-secret

machine-learning:
  enabled: false
    EOT
  ]
}

resource "kubernetes_namespace" "immich" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "immich-db" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Database"
    metadata = {
      name = "immich-db"
      namespace = var.namespace
    }
    spec = {
      name = "immich"
      owner = "immich"
      cluster = {
        name = "immich-cluster"
      }
    }
  }
}

resource "kubernetes_manifest" "immich-cluster" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind = "Cluster"
    metadata = {
      name = "immich-cluster"
      namespace = var.namespace
    }
    spec = {
      resources = {
        limits = {
          memory = "512Mi"
        }
        requests = {
          memory = "256Mi"
        }
      }
      imageName = "ghcr.io/tensorchord/cloudnative-vectorchord:16.13-1.1.1"
      postgresql = {
        shared_preload_libraries = [ "vchord.so" ]
      }
      bootstrap = {
        initdb = {
          postInitSQL = [
            "CREATE EXTENSION vchord CASCADE;",
            "CREATE EXTENSION earthdistance CASCADE;"
          ]
        }
      }
      instances = 2
      storage = {
        size = "1Gi"
      }
      monitoring = {
        enablePodMonitor = true
      }
      managed = {
        roles = [
          {
            name = "immich"
            ensure = "present"
            comment = "immich user"
            login = true
            superuser = false
            passwordSecret = {
              name = "immich-user-login"
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_secret" "immich-user-login" {
  metadata {
    name = "immich-user-login"
    namespace = var.namespace
    labels = {
      "cnpg.io/reload" = true
    }
  }
  data = {
    username = var.immich_user
    password = var.immich_user_pass
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_persistent_volume_claim" "immich-library" {
  metadata {
    name = "immich-library"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "nfs-client"
    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}
