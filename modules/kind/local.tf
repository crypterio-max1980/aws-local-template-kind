

provider "kind" {
}

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
}

resource "kind_cluster" "default" {
  name            = var.kind_cluster_name
  kubeconfig_path = pathexpand(var.kind_cluster_config_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role  = "control-plane"
      image = "kindest/node:${var.k8s_version}"

      kubeadm_config_patches = [
        <<-EOT
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    # Additional control planes for HA
    dynamic "node" {
      for_each = toset(range(var.additional_control_planes_count))
      content {
        role  = "control-plane"
        image = "kindest/node:${var.k8s_version}"
      }
    }
    # Additional workers
    dynamic "node" {
      for_each = toset(range(var.worker_count))
      content {
        role  = "worker"
        image = "kindest/node:${var.k8s_version}"
      }
    }
  }
}

resource "null_resource" "export_kubeconfig" {
  depends_on = [kind_cluster.default]

  provisioner "local-exec" {
    command = "echo 'export KUBECONFIG=${kind_cluster.default.kubeconfig_path}' >> ~/.bashrc"
  }
}
