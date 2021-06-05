resource "kubernetes_namespace" "flink_namespace" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_config_map" "flink_config" {
  depends_on = [
    "kubernetes_namespace.flink_namespace"
  ]

  metadata {
    name      = "flink-config"
    namespace = var.namespace

    labels = {
      app = "flink"
    }
  }

  data = {
    "flink-conf.yaml" = <<FLINK
      jobmanager.rpc.address: flink-jobmanager
      taskmanager.numberOfTaskSlots: 5
      blob.server.port: 6124
      jobmanager.rpc.port: 6123
      taskmanager.rpc.port: 6122
      queryable-state.proxy.ports: 6125
      jobmanager.memory.process.size: 1600m
      taskmanager.memory.process.size: 1728m
      parallelism.default: 2

      # Metrics
      metrics.reporter.prom.class: org.apache.flink.metrics.prometheus.PrometheusReporter
      metrics.reporter.prom.port: 9249-9260
    FLINK

    "log4j-console.properties" = <<LOG4J
      # This affects logging for both user code and Flink
      rootLogger.level = INFO
      rootLogger.appenderRef.console.ref = ConsoleAppender
      rootLogger.appenderRef.rolling.ref = RollingFileAppender

      # Uncomment this if you want to _only_ change Flink's logging
      #logger.flink.name = org.apache.flink
      #logger.flink.level = INFO

      # The following lines keep the log level of common libraries/connectors on
      # log level INFO. The root logger does not override this. You have to manually
      # change the log levels here.
      logger.akka.name = akka
      logger.akka.level = INFO
      logger.kafka.name= org.apache.kafka
      logger.kafka.level = INFO
      logger.hadoop.name = org.apache.hadoop
      logger.hadoop.level = INFO
      logger.zookeeper.name = org.apache.zookeeper
      logger.zookeeper.level = INFO

      # Log all infos to the console
      appender.console.name = ConsoleAppender
      appender.console.type = CONSOLE
      appender.console.layout.type = PatternLayout
      appender.console.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n

      # Log all infos in the given rolling file
      appender.rolling.name = RollingFileAppender
      appender.rolling.type = RollingFile
      appender.rolling.append = false
      appender.rolling.fileName = $${sys:log.file}
      appender.rolling.filePattern = $${sys:log.file}.%i
      appender.rolling.layout.type = PatternLayout
      appender.rolling.layout.pattern = %d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
      appender.rolling.policies.type = Policies
      appender.rolling.policies.size.type = SizeBasedTriggeringPolicy
      appender.rolling.policies.size.size=100MB
      appender.rolling.strategy.type = DefaultRolloverStrategy
      appender.rolling.strategy.max = 10

      # Suppress the irrelevant (wrong) warnings from the Netty channel handler
      logger.netty.name = org.apache.flink.shaded.akka.org.jboss.netty.channel.DefaultChannelPipeline
      logger.netty.level = OFF    
    LOG4J
  }
}

resource "kubernetes_service" "flink_jobmanager_rest" {
  depends_on = [
    "kubernetes_deployment.flink_jobmanager"
  ]

  metadata {
    name      = "flink-jobmanager-rest"
    namespace = var.namespace
  }

  spec {
    port {
      name        = "rest"
      port        = 8081
      target_port = "8081"
      node_port   = 30081
    }

    selector = {
      app = "flink"

      component = "jobmanager"
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "flink_jobmanager" {
  depends_on = [
    "kubernetes_deployment.flink_jobmanager"
  ]

  metadata {
    name      = "flink-jobmanager"
    namespace = var.namespace

    annotations = {
      "prometheus.io/port" = "9249"

      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      name = "rpc"
      port = 6123
    }

    port {
      name = "blob-server"
      port = 6124
    }

    port {
      name = "webui"
      port = 8081
    }

    port {
      name = "prom"
      port = 9249
    }

    selector = {
      app = "flink"

      component = "jobmanager"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "flink_jobmanager" {
  depends_on = [
    "kubernetes_config_map.flink_config"
  ]

  metadata {
    name      = "flink-jobmanager"
    namespace = var.namespace
  }

  spec {
    replicas = 1 # Set the value to greater than 1 to start standby JobManagers

    selector {
      match_labels = {
        app = "flink"

        component = "jobmanager"
      }
    }

    template {
      metadata {
        labels = {
          app = "flink"

          component = "jobmanager"
        }
      }

      spec {
        volume {
          name = "flink-config-volume"

          config_map {
            name = "flink-config"

            items {
              key  = "flink-conf.yaml"
              path = "flink-conf.yaml"
            }

            items {
              key  = "log4j-console.properties"
              path = "log4j-console.properties"
            }
          }
        }

        container {
          name  = "jobmanager"
          image = "apache/flink:1.13.0-scala_2.11"
          # The following args overwrite the value of jobmanager.rpc.address configured in the configuration config map to POD_IP.
          args = ["jobmanager"]

          env {
            name = "POD_IP"

            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "status.podIP"
              }
            }
          }

          port {
            name           = "rpc"
            container_port = 6123
          }

          port {
            name           = "blob-server"
            container_port = 6124
          }

          port {
            name           = "webui"
            container_port = 8081
          }

          port {
            name           = "prom"
            container_port = 9249
          }

          volume_mount {
            name       = "flink-config-volume"
            mount_path = "/opt/flink/conf"
          }

          liveness_probe {
            tcp_socket {
              port = "6123"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
          }

          security_context {
            run_as_user = 9999
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flink_taskmanager_query_state" {
  depends_on = [
    "kubernetes_deployment.flink_taskmanager"
  ]

  metadata {
    name      = "flink-taskmanager-query-state"
    namespace = var.namespace
  }

  spec {
    port {
      name        = "query-state"
      port        = 6125
      target_port = "6125"
      node_port   = 30025
    }

    selector = {
      app = "flink"

      component = "taskmanager"
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "flink_taskmanager" {
  depends_on = [
    "kubernetes_deployment.flink_taskmanager"
  ]

  metadata {
    name      = "flink-taskmanager"
    namespace = var.namespace

    annotations = {
      "prometheus.io/port" = "9249"

      "prometheus.io/scrape" = "true"
    }
  }

  spec {
    port {
      name = "prom"
      port = 9249
    }

    selector = {
      app = "flink"

      component = "taskmanager"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "flink_taskmanager" {
  depends_on = [
    "kubernetes_deployment.flink_jobmanager"
  ]

  metadata {
    name      = "flink-taskmanager"
    namespace = var.namespace
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "flink"

        component = "taskmanager"
      }
    }

    template {
      metadata {
        labels = {
          app = "flink"

          component = "taskmanager"
        }
      }

      spec {
        volume {
          name = "flink-config-volume"

          config_map {
            name = "flink-config"

            items {
              key  = "flink-conf.yaml"
              path = "flink-conf.yaml"
            }

            items {
              key  = "log4j-console.properties"
              path = "log4j-console.properties"
            }
          }
        }

        container {
          name  = "taskmanager"
          image = "apache/flink:1.13.0-scala_2.11"
          args  = ["taskmanager"]

          port {
            name           = "rpc"
            container_port = 6122
          }

          port {
            name           = "query-state"
            container_port = 6125
          }

          port {
            name           = "prom"
            container_port = 9249
          }

          resources {
            limits = {
              cpu = "500m"
            }

            requests = {
              cpu = "200m"
            }
          }          

          volume_mount {
            name       = "flink-config-volume"
            mount_path = "/opt/flink/conf/"
          }

          liveness_probe {
            tcp_socket {
              port = "6122"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
          }

          security_context {
            run_as_user = 9999
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "flink_taskmanager" {
  depends_on = [
    "kubernetes_deployment.flink_taskmanager"
  ]

  metadata {
    name      = "flink-taskmanager"
    namespace = var.namespace
  }

  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = "flink-taskmanager"
      api_version = "apps/v1"
    }

    min_replicas                      = 3
    max_replicas                      = 10
    target_cpu_utilization_percentage = 50
  }
}