resource "helm_release" "frigate" {
  name = "frigate"
  repository = "https://blakeblackshear.github.io/blakeshome-charts/"
  chart = "frigate"
  namespace = var.namespace
  create_namespace = true

  values = [
    <<-EOT
    service:
      type: LoadBalancer
      annotations:
        metallb.universe.tf/loadBalancerIPs: "10.2.0.45"
        metallb.universe.tf/ip-allocated-from-pool: "default-pool"
    snapshots:
      enabled: false
    record:
      enabled: false
    motion:
      enabled: false
    detect:
      enabled: false
    persistence:
      config:
        enabled: true
        size: 200Mi
      media:
        enabled: true
        size: 20Gi
        skipuninstall: true
        storageClass: "nfs-client"
    ingress:
      enabled: true
      ingressClassName: nginx
      annotations:
        cert-manager.io/cluster-issuer: "le-christianbingman-com"
      hosts:
        - host: frigate.int.christianbingman.com
          paths:
            - path: '/'
              portName: http-auth
      tls:
        - secretName: frigate-web-https
          hosts:
            - frigate.int.christianbingman.com
    config: |
      tls:
        enabled: false
      mqtt:
        host: ${var.mqtt_host}
        user: ${var.mqtt_user}
        password: "${var.mqtt_pass}"
      cameras:
        plant_cam:
          record:
            enabled: true
            retain:
              days: 180
              mode: all
            export:
              timelapse_args: "-vf setpts=0.0002*PTS -r 30"
          motion:
            enabled: false
          detect:
            enabled: false
          ffmpeg:
            inputs:
              - path: "rtsp://${var.tapo_cam_username}:${var.tapo_cam_password}@${var.tapo_cam_ip}:554/stream1"
                roles:
                  - record
          onvif:
            host: ${var.tapo_cam_ip}
            port: 2020
            user: ${var.tapo_cam_username}
            password: "${var.tapo_cam_password}"
    EOT
  ]
}
