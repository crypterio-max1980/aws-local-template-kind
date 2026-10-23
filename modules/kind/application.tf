
### - Argo Events - ### 
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

### - OneUptime - ### 
resource "helm_release" "oneuptime" {
  name             = "oneuptime"
  repository       = "https://helm-chart.oneuptime.com"
  chart            = "oneuptime"
  namespace        = "oneuptime"
  create_namespace = true

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 1200

  depends_on = [
    helm_release.ingress_nginx
  ]
}

