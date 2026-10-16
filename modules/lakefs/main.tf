
resource "helm_release" "lakefs" {
  name       = "lakefs"
  repository = "https://charts.lakefs.io"
  chart      = "lakefs"
  namespace  = "lakefs"
  create_namespace = true

  # PostgreSQL embedded in the chart
  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.postgresqlUsername"
    value = "lakefs_user"
  }

  set {
    name  = "postgresql.postgresqlPassword"
    value = "lakefs_password"
  }

  set {
    name  = "postgresql.postgresqlDatabase"
    value = "lakefs_db"
  }

  set {
    name  = "blockstore.type"
    value = "s3"
  }

  set {
    name  = "blockstore.s3.region"
    value = "us-west-rack2"
  }

  set {
    name  = "blockstore.s3.endpoint"
    value = "http://minio.default.svc.cluster.local:9000"
  }

  set {
    name  = "blockstore.s3.credentials.accessKey"
    value = "root"
  }

  set {
    name  = "blockstore.s3.credentials.secretKey"
    value = "r9G$2vK!7pXq&dL@8zF#eB^4mN*1wQ0"
  }
}
