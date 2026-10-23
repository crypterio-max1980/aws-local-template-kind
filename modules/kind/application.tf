
### Argo Events
resource "helm_release" "argo_events" {
  name             = "argo-events"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-events"
  namespace        = "argo-events"
  version          = "2.4.9"
  create_namespace = true

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 900

  depends_on = [
    helm_release.ingress_nginx
  ]
}

### OneUptime namespace
resource "kubernetes_namespace_v1" "oneuptime" {
  metadata {
    name = "oneuptime"

    labels = {
      app = "oneuptime"
    }
  }

  depends_on = [
    helm_release.argo_events
  ]
}

### OneUptime
resource "helm_release" "oneuptime" {
  name       = "oneuptime"
  repository = "https://helm-chart.oneuptime.com"
  chart      = "oneuptime"
  namespace  = kubernetes_namespace_v1.oneuptime.metadata[0].name

  create_namespace = false

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 1200

  depends_on = [
    kubernetes_namespace_v1.oneuptime
  ]
}
