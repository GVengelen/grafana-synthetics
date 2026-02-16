# Grafana Synthetic Monitoring Alerts

# Data source for Synthetic Monitoring metrics
data "grafana_data_source" "prometheus" {
  name = "grafanacloud-gjvengelen-prom"
}

resource "grafana_rule_group" "synthetic_monitoring_alerts" {
  name             = "Synthetic Monitoring Alerts"
  folder_uid       = grafana_folder.synthetic_monitoring_alerts.uid
  interval_seconds = 60

  rule {
    name      = "SyntheticMonitoringCheckFailureAtLowSensitivity"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          avg by(instance, job, severity) (probe_check_success_rate)
        EOT
        refId         = "A"
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        refId = "C"
        type  = "classic_conditions"
        conditions = [
          {
            evaluator = {
              params = [1]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            query = {
              model  = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
      })
    }

    for            = "5m"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    annotations = {
      summary     = "check success below 100%"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} has a success rate of {{ printf \"%.1f\" $value }}%."
    }

    labels = {
      namespace = "synthetic_monitoring"
    }
  }

  rule {
    name      = "SyntheticCheckFailing"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          avg_over_time(probe_success[5m])
        EOT
        refId         = "A"
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        refId = "C"
        type  = "classic_conditions"
        conditions = [
          {
            evaluator = {
              params = [1]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            query = {
              model  = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
      })
    }

    for            = "2m"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    annotations = {
      summary     = "synthetic check failing"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} returned failure over the last five minutes."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "critical"
    }
  }

  rule {
    name      = "HighSyntheticCheckLatency"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          avg_over_time(probe_duration_seconds{check_type!="browser"}[5m])
        EOT
        refId         = "A"
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        refId = "C"
        type  = "classic_conditions"
        conditions = [
          {
            evaluator = {
              params = [5]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              model  = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
      })
    }

    for            = "5m"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    annotations = {
      summary     = "synthetic check latency high"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} latency {{ printf \"%.2f\" $value }}s exceeds 5s threshold."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "warning"
    }
  }

  rule {
    name      = "MultipleSyntheticChecksFailing"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          sum(probe_success == 0)
        EOT
        refId         = "A"
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        refId = "C"
        type  = "classic_conditions"
        conditions = [
          {
            evaluator = {
              params = [3]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              model  = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
      })
    }

    for            = "3m"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    annotations = {
      summary     = "multiple synthetic checks failing"
      description = "{{ printf \"%.0f\" $value }} synthetic checks are failing simultaneously."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "critical"
    }
  }

  rule {
    name      = "SyntheticCheckHttp5xxErrors"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          max_over_time(probe_http_status_code[5m])
        EOT
        refId         = "A"
        intervalMs    = 1000
        maxDataPoints = 43200
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        refId = "C"
        type  = "classic_conditions"
        conditions = [
          {
            evaluator = {
              params = [500]
              type   = "gte"
            }
            operator = {
              type = "and"
            }
            query = {
              model  = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
      })
    }

    for            = "1m"
    no_data_state  = "NoData"
    exec_err_state = "Alerting"

    annotations = {
      summary     = "synthetic check http 5xx"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} returned HTTP status {{ printf \"%.0f\" $value }}."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "critical"
    }
  }
}

# Step 6: Create a folder for organizing the synthetic monitoring alerts
resource "grafana_folder" "synthetic_monitoring_alerts" {
  title = "Synthetic Monitoring Alerts"
}

# Step 7: Create a notification policy for these alerts
resource "grafana_notification_policy" "synthetic_monitoring" {
  group_by      = ["alertname", "grafana_folder"]
  contact_point = grafana_contact_point.synthetic_monitoring_alerts.name

  group_wait      = "10s"
  group_interval  = "5m"
  repeat_interval = "12h"

  policy {
    matcher {
      label = "team"
      match = "="
      value = "platform"
    }
    contact_point   = grafana_contact_point.synthetic_monitoring_alerts.name
    group_wait      = "10s"
    group_interval  = "5m"
    repeat_interval = "4h"
  }
}

# Step:7 Contact point for synthetic monitoring alerts
resource "grafana_contact_point" "synthetic_monitoring_alerts" {
  name = "synthetic-monitoring-alerts"

  email {
    addresses = ["<your email address>"]
    subject   = "Grafana Synthetic Monitoring Alert"
    message   = <<-EOT
      Alert: {{ .GroupLabels.alertname }}
      
      {{ range .Alerts }}
      Summary: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
      {{ end }}
    EOT
  }
}
