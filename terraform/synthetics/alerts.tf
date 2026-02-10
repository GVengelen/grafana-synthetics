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
          avg by (instance, job, severity) (
            instance_job_severity:probe_success:mean5m{alert_sensitivity="low"}
          )
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
              params = [95]
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
      summary     = "check success below 95%"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} has a success rate of {{ printf \"%.1f\" $value }}%."
    }

    labels = {
      namespace = "synthetic_monitoring"
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
