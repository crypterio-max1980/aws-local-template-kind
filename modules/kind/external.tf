
###---ArgoCD
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "8.5.3" # Check for latest version if needed
  create_namespace = true

  cleanup_on_fail = true
  dependency_update = true

  values = [
    <<EOT

crds:
  install: true
  keep: true

server:
  service:
    type: ClusterIP

  extraArgs:
    - --insecure

  ingress:
    enabled: true
    ingressClassName: nginx
    hostname: argo-dev.crypterio.co

    tls: true

configs:
  cm:
    url: https://argo-dev.crypterio.co

  secret:
    argocdServerAdminPassword: "$2a$10$lgcvwdvggWeLl1AN14NWsePcWQczWHRQH2eiUNL9w/gN6NaelDl.G"

   EOT
  ]
  depends_on = [helm_release.ingress_nginx]
}

resource "null_resource" "wait_for_argocd" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the argocd controller will be installed...\n"
      kubectl wait --namespace ${helm_release.argocd.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=server \
        --timeout=60s
    EOF
  }
  depends_on = [helm_release.argocd]
}


resource "kubernetes_namespace_v1" "oneuptime" {
  metadata {
    name = "oneuptime"

    labels = {
      app         = "oneuptime"
      environment = var.environment
    }
  }
  depends_on = [helm_release.argocd]
}

resource "helm_release" "oneuptime" {
  name       = "oneuptime"
  repository = "https://helm-chart.oneuptime.com"
  chart      = "oneuptime"
  namespace  = kubernetes_namespace_v1.oneuptime.metadata[0].name

  wait    = true
  timeout = 1200

  depends_on = [
    kubernetes_namespace_v1.oneuptime
  ]
}



