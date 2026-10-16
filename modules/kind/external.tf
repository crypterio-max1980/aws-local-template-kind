
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
    hostname: argo-dev.appflex.io

    tls: true

configs:
  cm:
    url: https://argo-dev.appflex.io

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

###---Minio
resource "helm_release" "minio" {
  name             = "minio"
  namespace        = "default"
  repository       = "https://charts.min.io/"
  chart            = "minio"
  #version          = "5.1.6"  # check latest stable version
  create_namespace = true

  depends_on = [helm_release.argocd]
  values = [
    yamlencode({
      mode         = "standalone"
      replicas     = 1

      # Root credentials (use variable for security)
      rootUser     = "root"
      rootPassword = var.minio_root_password

      # Buckets to create automatically
      buckets = [
        { name = "velero" },
        { name = "airbyte" },
        { name = "anythingllm" },
        { name = "loki" }
      ]

      # Enable persistent storage
      persistence = {
        enabled = true
        size    = "10Gi"
      }

      # Service configuration
      service = {
        type = "ClusterIP"  # use NodePort or LoadBalancer if needed
        port = 9000         # default S3 API port
      }

      # Console UI service
      console = {
        enabled = true
        port    = 9001
      }

      # Resource requests & limits
      resources = {
        requests = {
          memory = "512Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "1Gi"
          cpu    = "1000m"
        }
      }
    })
  ]
}



