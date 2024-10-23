resource "helm_release" "prometheus-stack" {
  name = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  namespace = "prometheus-stack"
  create_namespace = true

  values = [
    <<-EOT
    coreDns:
      service:
        port: 10055
        targetPort: 10055
    nodeExporter:
      enabled: false
    prometheusOperator:
      logLevel: warn
    prometheus:
      prometheusSpec:
        podMonitorNamespaceSelector: {}
        podMonitorSelector: {}
        podMonitorSelectorNilUsesHelmValues: false
        ruleNamespaceSelector: {}
        ruleSelector: {}
        ruleSelectorNilUsesHelmValues: false
        serviceMonitorNamespaceSelector: {}
        serviceMonitorSelector: {}
        serviceMonitorSelectorNilUsesHelmValues: false
        retention: 1y
        retentionSize: 10GB
        storageSpec:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi
        additionalScrapeConfigs:
          - job_name: "netdata_all_hosts"
            scrape_interval: "15s"
            metrics_path: "/api/v1/allmetrics"
            honor_labels: true
            params:
              format:
                - "prometheus"
            static_configs:
              - targets:
                - "kube-master-int.christianbingman.com:19999"
                - "kube-worker-int-1.christianbingman.com:19999"
                - "kube-worker-int-2.christianbingman.com:19999"
                - "kube-worker-int-3.christianbingman.com:19999"
    grafana:
      ingress:
        enabled: true
        annotations:
          cert-manager.io/cluster-issuer: "le-christianbingman-com"
        hosts:
          - grafana.int.christianbingman.com
        tls:
          - secretName: grafana-general-tls
            hosts:
            - grafana.int.christianbingman.com

      assertNoLeakedSecrets: false
      sidecar:
        alerts:
          enabled: true
          searchNamespace: ALL
        dashboards:
          enabled: true
          searchNamespace: ALL
      alerting:
        contactpoints.yaml:
          apiVersion: 1
          contactPoints:
            - orgId: 1
              name: Default Mail
              receivers:
                - uid: default-mail
                  type: email
                  settings:
                    addresses: alerts@christianbingman.com
      grafana.ini:
        smtp:
          enabled: true
          host: "${var.smtp_host}"
          user: "${var.smtp_user}"
          password: "${var.smtp_pass}"
          from_address: "${var.smtp_from_address}"
          from_name: "${var.smtp_from_name}"
      adminPassword: "${var.admin_password}"
    EOT
  ]
}
