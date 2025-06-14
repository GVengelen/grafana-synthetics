# Grafana Synthetic Monitoring Alerts

# Data source for Synthetic Monitoring metrics
data "grafana_data_source" "prometheus" {
  name = "grafanacloud-gjvengelen-prom"
}

# Step 1: Target Down Alert - fires when a target is down across all probes
resource "grafana_rule_group" "synthetic_monitoring_alerts" {
  name             = "Synthetic Monitoring Alerts"
  folder_uid       = grafana_folder.synthetic_monitoring_alerts.uid
  interval_seconds = 60

  rule {
    name      = "Target Down - All Probes Failing"
    condition = "C"
    
    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = <<-EOT
          sum by (instance, job) (rate(probe_all_success_sum{}[10m]))
          /
          sum by (instance, job) (rate(probe_all_success_count{}[10m]))
        EOT
        refId      = "A"
        intervalMs = 1000
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
        conditions = [
          {
            evaluator = {
              params = [0]
              type   = "eq"
            }
            operator = {
              type = "and"
            }
            query = {
              model = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        refId = "C"
        type  = "classic_conditions"
      })
    }

    for    = "5m"
    no_data_state   = "NoData"
    exec_err_state  = "Alerting"
    
    annotations = {
      summary     = "Target {{ $labels.instance }} ({{ $labels.job }}) is down - all probes failing"
      description = "The target {{ $labels.instance }} for job {{ $labels.job }} has been unreachable from all probes for more than 5 minutes."
    }
    
    labels = {
      severity = "critical"
      team     = "platform"
    }
  }

  # Step 2: Reachability Alert - fires when reachability drops below 90%
  rule {
    name      = "Low Reachability - Below 90%"
    condition = "C"
    
    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = <<-EOT
          sum by (instance, job) (rate(probe_all_success_sum{}[10m]))
          /
          sum by (instance, job) (rate(probe_all_success_count{}[10m]))
        EOT
        refId      = "A"
        intervalMs = 1000
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
        conditions = [
          {
            evaluator = {
              params = [0.9]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            query = {
              model = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        refId = "C"
        type  = "classic_conditions"
      })
    }

    for    = "5m"
    no_data_state   = "NoData"
    exec_err_state  = "Alerting"
    
    annotations = {
      summary     = "Low reachability for {{ $labels.instance }} ({{ $labels.job }})"
      description = "Reachability for {{ $labels.instance }} ({{ $labels.job }}) has dropped below 90% (currently {{ $value | humanizePercentage }})."
    }
    
    labels = {
      severity = "warning"
      team     = "platform"
    }
  }

  # Step 3: High Latency Alert - fires when average latency goes above 1 second
  rule {
    name      = "High Latency - Above 1 Second"
    condition = "C"
    
    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = <<-EOT
          sum by (instance, job) (rate(probe_all_duration_seconds_sum{}[10m]))
          /
          sum by (instance, job) (rate(probe_all_duration_seconds_count{}[10m]))
        EOT
        refId      = "A"
        intervalMs = 1000
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
        conditions = [
          {
            evaluator = {
              params = [1]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              model = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        refId = "C"
        type  = "classic_conditions"
      })
    }

    for    = "5m"
    no_data_state   = "NoData"
    exec_err_state  = "Alerting"
    
    annotations = {
      summary     = "High latency for {{ $labels.instance }} ({{ $labels.job }})"
      description = "Average latency for {{ $labels.instance }} ({{ $labels.job }}) is above 1 second (currently {{ $value }}s)."
    }
    
    labels = {
      severity = "warning"
      team     = "platform"
    }
  }

  # Step 4: High Error Rate Alert - fires when error rate is above 10%
  rule {
    name      = "High Error Rate - Above 10%"
    condition = "C"
    
    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = <<-EOT
          1 - (
            sum by (instance, job) (rate(probe_all_success_sum{}[10m]))
            /
            sum by (instance, job) (rate(probe_all_success_count{}[10m]))
          )
        EOT
        refId      = "A"
        intervalMs = 1000
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
        conditions = [
          {
            evaluator = {
              params = [0.1]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              model = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        refId = "C"
        type  = "classic_conditions"
      })
    }

    for    = "5m"
    no_data_state   = "NoData"
    exec_err_state  = "Alerting"
    
    annotations = {
      summary     = "High error rate for {{ $labels.instance }} ({{ $labels.job }})"
      description = "Error rate for {{ $labels.instance }} ({{ $labels.job }}) is above 10% (currently {{ $value | humanizePercentage }})."
    }
    
    labels = {
      severity = "warning"
      team     = "platform"
    }
  }

  # Step 5: High Error Rate by Probe Alert - fires when error rate on a specific probe is above 50%
  rule {
    name      = "High Error Rate by Probe - Above 50%"
    condition = "C"
    
    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = <<-EOT
          1 - (
            sum by (instance, job, probe) (rate(probe_all_success_sum{}[10m]))
            /
            sum by (instance, job, probe) (rate(probe_all_success_count{}[10m]))
          )
        EOT
        refId      = "A"
        intervalMs = 1000
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
        conditions = [
          {
            evaluator = {
              params = [0.5]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              model = ""
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        refId = "C"
        type  = "classic_conditions"
      })
    }

    for    = "5m"
    no_data_state   = "NoData"
    exec_err_state  = "Alerting"
    
    annotations = {
      summary     = "High error rate on probe {{ $labels.probe }} for {{ $labels.instance }} ({{ $labels.job }})"
      description = "Error rate on probe {{ $labels.probe }} for {{ $labels.instance }} ({{ $labels.job }}) is above 50% (currently {{ $value | humanizePercentage }})."
    }
    
    labels = {
      severity = "warning"
      team     = "platform"
      probe    = "{{ $labels.probe }}"
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
    addresses = ["g.vanengelen@codepeople.nl"]
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
