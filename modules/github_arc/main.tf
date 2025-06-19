locals {
  runner_version = "2.324.0"
}

resource "helm_release" "github-arc" {
  name = "arc-runners"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/"
  chart = "gha-runner-scale-set-controller"
  namespace = var.controller_namespace
  create_namespace = true
  version = "0.11.0"
}

resource "helm_release" "christianbingman-com-runners" {
  depends_on = [helm_release.github-arc]
  name = "christianbingman-com-runners"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/"
  chart = "gha-runner-scale-set"
  namespace = var.runner_namespace
  create_namespace = true
  version = "0.11.0"
  set {
    name = "githubConfigUrl"
    value = "https://github.com/ChristianBingman/christianbingman.com"
  }
  set {
    name = "githubConfigSecret.github_token"
    value = var.github_pat
  }
  values = [
    <<-EOT
    template:
      spec:
        initContainers:
          - name: init-dind-externals
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command:
              ["cp", "-r", "/home/runner/externals/.", "/home/runner/tmpDir/"]
            volumeMounts:
              - name: dind-externals
                mountPath: /home/runner/tmpDir
        containers:
          - name: runner
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command: ["/home/runner/run.sh"]
            env:
              - name: DOCKER_HOST
                value: unix:///var/run/docker.sock
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
          - name: dind
            image: docker:dind
            args:
              - dockerd
              - --host=unix:///var/run/docker.sock
              - --group=$(DOCKER_GROUP_GID)
            env:
              - name: DOCKER_GROUP_GID
                value: "123"
            securityContext:
              privileged: true
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
              - name: dind-externals
                mountPath: /home/runner/externals
        volumes:
          - name: work
            emptyDir: {}
          - name: dind-sock
            emptyDir: {}
          - name: dind-externals
            emptyDir: {}
    EOT
  ]
}

resource "helm_release" "anki-sync-server-runners" {
  depends_on = [helm_release.github-arc]
  name = "anki-sync-server-runners"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/"
  chart = "gha-runner-scale-set"
  namespace = var.runner_namespace
  create_namespace = true
  version = "0.11.0"
  set {
    name = "githubConfigUrl"
    value = "https://github.com/ChristianBingman/anki-sync-server"
  }
  set {
    name = "githubConfigSecret.github_token"
    value = var.github_pat
  }
  values = [
    <<-EOT
    template:
      spec:
        initContainers:
          - name: init-dind-externals
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command:
              ["cp", "-r", "/home/runner/externals/.", "/home/runner/tmpDir/"]
            volumeMounts:
              - name: dind-externals
                mountPath: /home/runner/tmpDir
        containers:
          - name: runner
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command: ["/home/runner/run.sh"]
            env:
              - name: DOCKER_HOST
                value: unix:///var/run/docker.sock
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
          - name: dind
            image: docker:dind
            args:
              - dockerd
              - --host=unix:///var/run/docker.sock
              - --group=$(DOCKER_GROUP_GID)
            env:
              - name: DOCKER_GROUP_GID
                value: "123"
            securityContext:
              privileged: true
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
              - name: dind-externals
                mountPath: /home/runner/externals
        volumes:
          - name: work
            emptyDir: {}
          - name: dind-sock
            emptyDir: {}
          - name: dind-externals
            emptyDir: {}
    EOT
  ]
}

resource "helm_release" "private-finance-runners" {
  depends_on = [helm_release.github-arc]
  name = "private-finance-runners"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts/"
  chart = "gha-runner-scale-set"
  namespace = var.runner_namespace
  create_namespace = true
  version = "0.11.0"
  set {
    name = "githubConfigUrl"
    value = "https://github.com/ChristianBingman/PrivateFinance"
  }
  set {
    name = "githubConfigSecret.github_token"
    value = var.github_pat
  }
  values = [
    <<-EOT
    template:
      spec:
        initContainers:
          - name: init-dind-externals
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command:
              ["cp", "-r", "/home/runner/externals/.", "/home/runner/tmpDir/"]
            volumeMounts:
              - name: dind-externals
                mountPath: /home/runner/tmpDir
        containers:
          - name: runner
            image: ghcr.io/actions/actions-runner:${local.runner_version}
            command: ["/home/runner/run.sh"]
            env:
              - name: DOCKER_HOST
                value: unix:///var/run/docker.sock
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
          - name: dind
            image: docker:dind
            args:
              - dockerd
              - --host=unix:///var/run/docker.sock
              - --group=$(DOCKER_GROUP_GID)
            env:
              - name: DOCKER_GROUP_GID
                value: "123"
            securityContext:
              privileged: true
            volumeMounts:
              - name: work
                mountPath: /home/runner/_work
              - name: dind-sock
                mountPath: /var/run
              - name: dind-externals
                mountPath: /home/runner/externals
        volumes:
          - name: work
            emptyDir: {}
          - name: dind-sock
            emptyDir: {}
          - name: dind-externals
            emptyDir: {}
    EOT
  ]
}
