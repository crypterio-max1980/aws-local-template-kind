
resource "helm_release" "datahub_prerequisites" {
  name             = "datahub-prerequisites"
  repository       = "https://helm.datahubproject.io/"
  chart            = "datahub-prerequisites"
  namespace        = "datahub"
  create_namespace = true

  set {
    name  = "mysql.auth.rootPassword"
    value = "super-secret-password"
  }

  set {
    name  = "neo4j.password"
    value = "another-secret"
  }
}

resource "helm_release" "datahub" {
  name       = "datahub"
  repository = "https://helm.datahubproject.io/"
  chart      = "datahub"
  namespace  = "datahub"

  depends_on = [helm_release.datahub_prerequisites]

  # Example: expose frontend as LoadBalancer
  set {
    name  = "datahub-frontend.service.type"
    value = "LoadBalancer"
  }

  # Example: use Elasticsearch as graph store
  set {
    name  = "global.graph_service_impl"
    value = "elasticsearch"
  }

  # Example: enable ingestion
  set {
    name  = "datahub-ingestion.enabled"
    value = "true"
  }
}
