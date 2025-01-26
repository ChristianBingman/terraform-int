terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.15.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "metrics-server" {
   source = "./modules/metrics_server"
}

module "cert-manager" {
  source = "./modules/cert-manager"
  cloudflare_api_token = var.cert-manager_cloudflare_api_token
  servicemonitor_enabled = true
  depends_on = [module.prometheus-stack]
}

module "longhorn" {
  source = "./modules/longhorn"
  smb_username = var.longhorn_smb_username
  smb_password = var.longhorn_smb_password
}

module "nfs-subdir" {
  source = "./modules/nfs-subdir-external-provisioner"
}

module "prometheus-stack" {
  source = "./modules/prometheus-stack"
  admin_password = var.prometheus-stack_grafana_admin_password
  smtp_host = var.smtp_host
  smtp_user = var.smtp_user
  smtp_pass = var.smtp_pass
  depends_on = [module.longhorn]
  oidc_client_id = var.grafana_oidc_client_id
  oidc_client_secret = var.grafana_oidc_client_secret
}

module "metallb" {
  source = "./modules/metallb"
}

module "eck-operator" {
  source = "./modules/eck"
  depends_on = [module.longhorn]
}

module "github-arc" {
  source = "./modules/github_arc"
  github_pat = var.github_pat
}

module "elasticsearch-int" {
  source = "./modules/elasticsearch-int"
  depends_on = [module.eck-operator, module.nfs-subdir]
}

module "nginx-ingress" {
  source = "./modules/nginx_ingress"
  metallb_ip = "10.2.0.41"
}

module "argocd" {
  source = "./modules/argocd"
  dex_client_secret = var.argocd_dex_client_secret
}

module "grafana-dashboards" {
  source = "./modules/grafana-dashboards"
}

module "searxng" {
  source = "./modules/searxng"
  basic_auth = var.searxng_public_auth_htpasswd
}

module "mosquitto" {
  source = "./modules/mosquitto"
  admin_login = var.mosquitto_admin_login
}

module "frigate" {
  source = "./modules/frigate"
  tapo_cam_ip = var.frigate_tapo_cam_ip
  tapo_cam_username = var.frigate_tapo_cam_username
  tapo_cam_password = var.frigate_tapo_cam_password
  mqtt_host = var.mqtt_host
  mqtt_user = var.mqtt_admin_user
  mqtt_pass = var.mqtt_admin_pass
}

module "cloudflare-tunnel" {
  source = "./modules/cloudflare-tunnel"
  credentials = var.cloudflare-tunnel_credentials
}

module "authentik" {
  source = "./modules/authentik"
  pg_pass = var.authentik_postgres_pw
  authentik_secret = var.authentik_secret
}
