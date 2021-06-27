resource "kubernetes_cluster_role_binding" "flink_role_binding_flink" {
  metadata {
    name = "flink-role-binding-flink"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flink-service-account"
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
}

resource "kubernetes_service_account" "flink_service_account" {
  metadata {
    name      = "flink-service-account"
    namespace = var.namespace
  }
}

