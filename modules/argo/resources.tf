
###---Application---###
resource "argocd_application" "httpd" {
  metadata {
    name      = "httpd"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/crypto1980/deployment.git"
      target_revision = "HEAD"
      path            = "httpd"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    sync_policy {
      automated {
        prune = true
        self_heal = true
      }
    }
  }
}
