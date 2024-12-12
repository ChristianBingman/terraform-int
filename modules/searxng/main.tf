resource "helm_release" "searxng" {
  name = "searxng"
  repository = "https://charts.searxng.org"
  chart = "searxng"
  namespace = var.namespace
  create_namespace = true

  set {
    name = "env.TZ"
    value = "America/Chicago"
  }

  set {
    name = "env.INSTANCE_NAME"
    value = "Christian's Searxng Instance"
  }

  set {
    name = "env.BASE_URL"
    value = "https://search.int.christianbingman.com"
  }

  set {
    name = "env.AUTOCOMPLETE"
    value = "true"
  }

  values = [
    <<-EOT
    ingress:
      main:
        enabled: true
        annotations:
          cert-manager.io/cluster-issuer: "le-christianbingman-com"
          nginx.ingress.kubernetes.io/auth-type: basic
          nginx.ingress.kubernetes.io/auth-secret: basic-auth
          nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
        hosts:
          - host: search.int.christianbingman.com
            paths:
              - path: /
                pathType: Prefix
          - host: search.christianbingman.com
            paths:
              - path: /
                pathType: Prefix
        tls:
          - hosts:
            - search.int.christianbingman.com
            - search.christianbingman.com
            # Based on the ingress controller used secret might be optional
            secretName: searxng-http-tls
    EOT
  ]
}

resource "kubernetes_secret" "basic-auth-secret" {
  metadata {
    name = "basic-auth"
    namespace = var.namespace
  }
  data = {
    auth = var.basic_auth
  }
  type = "generic"
}
