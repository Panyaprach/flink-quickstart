resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_config_map" "prometheus_cm" {
  metadata {
    name      = "prometheus-cm"
    namespace = "prometheus"
  }

  data = {
    "prometheus.yml" = <<CONF
    global:
      evaluation_interval: 1m
      scrape_interval: 1m
      scrape_timeout: 10s
    rule_files:
      - /etc/config/recording_rules.yml
      - /etc/config/alerting_rules.yml
      - /etc/config/rules
      - /etc/config/alerts
    scrape_configs:
      - job_name: prometheus
        static_configs:
        - targets:
          - localhost:9090
      - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        job_name: kubernetes-apiservers
        kubernetes_sd_configs:
        - role: endpoints
        relabel_configs:
        - action: keep
          regex: default;kubernetes;https
          source_labels:
          - __meta_kubernetes_namespace
          - __meta_kubernetes_service_name
          - __meta_kubernetes_endpoint_port_name
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
      - job_name: kubernetes-nodes
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - replacement: kubernetes.default.svc:443
          target_label: __address__
        - regex: (.+)
          replacement: /api/v1/nodes/$1/proxy/metrics
          source_labels:
          - __meta_kubernetes_node_name
          target_label: __metrics_path__
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
      - job_name: kubernetes-nodes-cadvisor
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - replacement: kubernetes.default.svc:443
          target_label: __address__
        - regex: (.+)
          replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
          source_labels:
          - __meta_kubernetes_node_name
          target_label: __metrics_path__
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true                
      - job_name: kubernetes-service-endpoints
        kubernetes_sd_configs:
        - role: endpoints
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_scrape
        - action: replace
          regex: (https?)
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_scheme
          target_label: __scheme__
        - action: replace
          regex: (.+)
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_path
          target_label: __metrics_path__
        - action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          source_labels:
          - __address__
          - __meta_kubernetes_service_annotation_prometheus_io_port
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - action: replace
          source_labels:
          - __meta_kubernetes_namespace
          target_label: kubernetes_namespace
        - action: replace
          source_labels:
          - __meta_kubernetes_service_name
          target_label: kubernetes_name
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_node_name
          target_label: kubernetes_node
      - job_name: kubernetes-service-endpoints-slow
        kubernetes_sd_configs:
        - role: endpoints
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_scrape_slow
        - action: replace
          regex: (https?)
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_scheme
          target_label: __scheme__
        - action: replace
          regex: (.+)
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_path
          target_label: __metrics_path__
        - action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          source_labels:
          - __address__
          - __meta_kubernetes_service_annotation_prometheus_io_port
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - action: replace
          source_labels:
          - __meta_kubernetes_namespace
          target_label: kubernetes_namespace
        - action: replace
          source_labels:
          - __meta_kubernetes_service_name
          target_label: kubernetes_name
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_node_name
          target_label: kubernetes_node
        scrape_interval: 5m
        scrape_timeout: 30s
      - job_name: kubernetes-services
        kubernetes_sd_configs:
        - role: service
        metrics_path: /probe
        params:
          module:
          - http_2xx
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_service_annotation_prometheus_io_probe
        - source_labels:
          - __address__
          target_label: __param_target
        - replacement: blackbox
          target_label: __address__
        - source_labels:
          - __param_target
          target_label: instance
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels:
          - __meta_kubernetes_namespace
          target_label: kubernetes_namespace
        - source_labels:
          - __meta_kubernetes_service_name
          target_label: kubernetes_name
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape
        - action: replace
          regex: (https?)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scheme
          target_label: __scheme__
        - action: replace
          regex: (.+)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_path
          target_label: __metrics_path__
        - action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          source_labels:
          - __address__
          - __meta_kubernetes_pod_annotation_prometheus_io_port
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - action: replace
          source_labels:
          - __meta_kubernetes_namespace
          target_label: kubernetes_namespace
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_name
          target_label: kubernetes_pod_name
        - action: drop
          regex: Pending|Succeeded|Failed
          source_labels:
          - __meta_kubernetes_pod_phase
      - job_name: kubernetes-pods-slow
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow
        - action: replace
          regex: (https?)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scheme
          target_label: __scheme__
        - action: replace
          regex: (.+)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_path
          target_label: __metrics_path__
        - action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          source_labels:
          - __address__
          - __meta_kubernetes_pod_annotation_prometheus_io_port
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - action: replace
          source_labels:
          - __meta_kubernetes_namespace
          target_label: kubernetes_namespace
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_name
          target_label: kubernetes_pod_name
        - action: drop
          regex: Pending|Succeeded|Failed
          source_labels:
          - __meta_kubernetes_pod_phase
        scrape_interval: 5m
        scrape_timeout: 30s
      # alerting:
      #   alertmanagers:
      #   - kubernetes_sd_configs:
      #       - role: pod
      #     tls_config:
      #       ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      #     bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      #     relabel_configs:
      #     - source_labels: [__meta_kubernetes_namespace]
      #       regex: prometheus
      #       action: keep
      #     - source_labels: [__meta_kubernetes_pod_label_app]
      #       regex: prometheus
      #       action: keep
      #     - source_labels: [__meta_kubernetes_pod_label_component]
      #       regex: alertmanager
      #       action: keep
      #     - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_probe]
      #       regex: .*
      #       action: keep
      #     - source_labels: [__meta_kubernetes_pod_container_port_number]
      #       regex: "9093"
      #       action: keep              
  CONF
  }
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "prometheus-k8s"
    namespace = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "prometheus"
  }
}

resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["configmaps"]
  }

  rule {
    verbs             = ["get"]
    non_resource_urls = ["/metrics"]
  }
}

resource "kubernetes_service_account" "prometheus_k_8_s" {
  metadata {
    name      = "prometheus-k8s"
    namespace = "prometheus"
  }
}

resource "kubernetes_deployment" "prometheus_server" {
  metadata {
    name      = "prometheus-server"
    namespace = "prometheus"

    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        volume {
          name = "config-volume"

          config_map {
            name = "prometheus-cm"
          }
        }

        container {
          name  = "prometheus"
          image = "prom/prometheus"

          port {
            container_port = 9090
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/prometheus/prometheus.yml"
            sub_path   = "prometheus.yml"
          }
        }

        service_account_name = "prometheus-k8s"
      }
    }
  }
}

resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "prometheus"
  }

  spec {
    port {
      name        = "promui"
      protocol    = "TCP"
      port        = 9090
      target_port = "9090"
    }

    selector = {
      app = "prometheus"
    }
  }
}

