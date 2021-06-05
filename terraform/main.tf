terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "flink" {
  source = "./flink"
}

# resource "null_resource" "restart_flink_deployments" {

#   provisioner "local-exec" {
#     working_dir = "../scripts"
#     command     = "./rollout-restart.sh flink"
#   }
# }

# module "prometheus" {
#   source = "./prometheus"
# }