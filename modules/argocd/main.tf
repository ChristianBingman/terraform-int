resource "helm_release" "argocd" {
  name       = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace
  create_namespace = true

  values = [
    <<-EOT
    global:
      domain: argocd.int.christianbingman.com

    configs:
      secret:
        extra:
          dex.authentik.clientSecret: ${var.dex_client_secret}
      params:
        server.insecure: true

    server:
      ingress:
        enabled: true
        ingressClassName: nginx
        annotations:
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
          nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
          cert-manager.io/cluster-issuer: "le-christianbingman-com"
        extraTls:
          - hosts:
            - argocd.int.christianbingman.com
            # Based on the ingress controller used secret might be optional
            secretName: wildcard-tls
    EOT
  ]

}
