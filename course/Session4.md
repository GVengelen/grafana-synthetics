# Session 4: Alerting and Performance Monitoring (90 minutes)

## Introduction
In this session, we'll build upon our synthetic monitoring infrastructure by adding alerts. At the end of this session, you'll have a complete alerting system that notifies you when your services experience issues, allowing for proactive monitoring and rapid incident response.

### Why Synthetic Monitoring Alerts Matter
Alerting is the important, without proper alerts:

- **Silent Failures**: Issues can go unnoticed until customers report them
- **Delayed Response**: Late detection leads to longer outages and more impact
- **No Context**: Manual checking provides limited historical data
- **Inconsistent Monitoring**: Different team members may check different things
- **Alert Fatigue**: Too many false positives reduce team responsiveness

With automated synthetic monitoring alerts:
- **Proactive Detection**: Know about issues before customers do
- **Contextual Information**: Rich metadata helps with faster troubleshooting
- **Consistent Standards**: Everyone gets the same alerts based on the same criteria
- **Historical Tracking**: Build a database of incidents and patterns
- **Scalable Monitoring**: Alert on hundreds of services without manual oversight

## Understanding Grafana Alerting Architecture

### Key Components
Grafana's unified alerting system consists of several key components:

1. **Alert Rules**: Define the conditions that trigger alerts
2. **Data Sources**: Where alert rules query data from (Prometheus, Loki, etc.)
3. **Evaluation Groups**: Collections of alert rules that are evaluated together
4. **Contact Points**: Define how and where to send alert notifications
5. **Notification Policies**: Route alerts to appropriate contact points based on labels
6. **Silences**: Temporarily mute alerts during maintenance or known issues

### Alert Rule Anatomy
Each alert rule contains:
- **Query**: The metric query that provides data
- **Condition**: The threshold or condition that triggers the alert
- **Evaluation**: How often to check the condition
- **Annotations**: Human-readable context about the alert
- **Labels**: Metadata used for routing and grouping

## Core Synthetic Monitoring Metrics
Before we create our alerts, let's understand the key metrics that Grafana Synthetics provides:

### Success Rate Metrics
- `probe_all_success_sum`: Total number of successful probes
- `probe_all_success_count`: Total number of probe attempts
- **Usage**: Calculate availability percentage and error rates

### Duration Metrics  
- `probe_all_duration_seconds_sum`: Total time spent on all probes
- `probe_all_duration_seconds_count`: Number of probe duration measurements
- **Usage**: Calculate average response times and latency

### HTTP-Specific Metrics
- `probe_http_status_code`: HTTP response codes
- `probe_http_duration_seconds`: HTTP-specific timing metrics
- **Usage**: Monitor specific HTTP behaviors

### Labels Available
- `instance`: The target being monitored
- `job`: The job name from your synthetic check
- `probe`: The geographic location running the check
- `check_name`: Name of your synthetic check

## Hands-on: Building a Complete Alerting System

In this exercise, we'll create an alerting system for our synthetic monitoring checks. We'll add the top 5 alert rules as described [here](https://grafana.com/blog/2022/01/11/top-5-user-requested-synthetic-monitoring-alerts-in-grafana-cloud/)

### Step 1: Adding the Prometheus Data Source

Before creating alerts, we need to identify our Prometheus data source. In Grafana Cloud, synthetic monitoring metrics are stored in a Prometheus instance.

First, let's create our alerts file structure:

```bash
cd terraform/synthetics
touch alerts.tf
```

Now, let's start by creating a data source reference. Add the following to your `alerts.tf` file:

```terraform
# Grafana Synthetic Monitoring Alerts

# Data source for Synthetic Monitoring metrics
data "grafana_data_source" "prometheus" {
  name = "{your-prometheus-datasource}"
}
```

**Important**: Replace `your-prometheus-datasource` with your actual Prometheus data source name. You can find this in your Grafana Cloud instance under Configuration → Data Sources.

### Step 2: Creating Your First Alert - Target Down Detection

Let's start with the most critical alert: detecting when a target is completely down. This alert will fire when all probes are failing for a target.

Add the following to your `alerts.tf` file:

```terraform
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
}
```

Let's break down what this alert does:

| Component | Purpose | Details |
|-----------|---------|---------|
| `rule_group` | Container for related alert rules | Groups rules that should be evaluated together |
| `name` | Human-readable identifier | Shows up in Grafana UI and notifications |
| `condition` | References the data query that triggers | "C" refers to our condition query |
| `data` block A | Main metric query | Calculates success rate over 10 minutes |
| `data` block C | Condition evaluation | Triggers when success rate equals 0 (completely down) |
| `for` | Sustained duration | Alert only fires after condition is true for 5 minutes |
| `annotations` | Context for humans | Summary and description appear in notifications |
| `labels` | Metadata for routing | Used by notification policies to route alerts |

The PromQL query `sum by (instance, job) (rate(probe_all_success_sum{}[10m])) / sum by (instance, job) (rate(probe_all_success_count{}[10m]))` calculates the success rate by dividing successful probes by total probe attempts over a 10-minute window.

### Step 3: Adding a Reachability Alert

Now let's add an alert for when reachability drops below acceptable levels, but isn't completely down:

```terraform
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
```

This alert uses the same success rate query but triggers when the value is less than 0.9 (90%). Note the `severity = "warning"` label - this is less critical than a complete outage.

### Step 4: Performance Monitoring - High Latency Alert

Performance matters as much as availability. Let's add an alert for high latency:

```terraform
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
```

This alert uses duration metrics (`probe_all_duration_seconds_sum` and `probe_all_duration_seconds_count`) to calculate average response time. It triggers when the average exceeds 1 second.

### Step 5: Error Rate Monitoring

Let's add an alert for monitoring overall error rates:

```terraform
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
```

This query calculates error rate by subtracting the success rate from 1 (`1 - success_rate = error_rate`). It triggers when errors exceed 10%.

### Step 6: Geographic-Specific Monitoring

Sometimes a specific geographic location may have issues while others work fine. Let's add probe-specific monitoring:

```terraform
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
```

This alert includes the `probe` dimension in the query (`sum by (instance, job, probe)`), allowing us to detect issues specific to geographic locations.

### Step 7: Creating an Alert Folder

Organization is key for managing alerts at scale. Let's create a dedicated folder:

```terraform
# Step 6: Create a folder for organizing the synthetic monitoring alerts
resource "grafana_folder" "synthetic_monitoring_alerts" {
  title = "Synthetic Monitoring Alerts"
}
```

This folder will contain all our synthetic monitoring alerts, making them easy to find and manage in the Grafana UI.

### Step 8: Setting Up Contact Points

Alerts are useless if nobody receives them. Let's create a contact point for notifications:

```terraform
# Step 7: Contact point for synthetic monitoring alerts
resource "grafana_contact_point" "synthetic_monitoring_alerts" {
  name = "synthetic-monitoring-alerts"

  email {
    addresses = ["your-email@example.com"]
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
```

**Important**: Replace `your-email@example.com` with your actual email address.

The message template uses Grafana's template language to include:
- Alert name
- Summary and description from annotations
- All labels for context

### Step 9: Creating Notification Policies

Contact points define *how* to send alerts, but notification policies define *when* and *to whom*. Let's set up routing:

```terraform
# Step 8: Create a notification policy for these alerts
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
```

This policy:
- **Groups alerts** by alert name and folder to reduce notification spam
- **Waits 10 seconds** before sending initial notifications (allows multiple alerts to group)
- **Groups similar alerts** for 5 minutes before sending additional notifications
- **Repeats notifications** every 12 hours for unresolved alerts
- **Routes team=platform alerts** to our contact point with more frequent repeats (4 hours)

### Step 10: Deploying Your Alerting System

Now let's deploy our complete alerting system:

```bash
cd terraform/synthetics
```

First, let's validate our configuration:

```bash
terraform validate
```

If validation passes, let's see what changes will be made:

```bash
terraform plan -var-file="../envs/dev/secrets.auto.tfvars"
```

Review the planned changes. You should see something like this:
- 1 data source to be read
- 1 rule group with 5 alert rules
- 1 folder for organization
- 1 contact point for notifications
- 1 notification policy for routing

If everything looks correct, apply the changes by merging our changes to main.

### Step 11: Testing Your Alerts

Once deployed, you can test your alerts in several ways:

#### Method 1: Using Grafana UI
1. Navigate to your Grafana Cloud instance
2. Go to Alerting → Alert Rules
3. Find your "Synthetic Monitoring Alerts" folder
4. Click on any rule to see its current state and evaluation history

#### Method 2: Temporarily Breaking a Check
You can temporarily modify one of your synthetic checks to point to a non-existent endpoint:

```bash
# Backup your current main.tf
cp main.tf main.tf.backup


```
Edit main.tf to change a target URL to something that will fail. For example, change your HTTP check target to "https://this-will-fail.example.com". Deploy the change and wait for alerts to fire, then restore your backup.

## Understanding Alert States and Lifecycle

### Alert States
Grafana alerts can be in several states:

- **Normal**: Condition is false, no alert
- **Pending**: Condition is true but hasn't exceeded the `for` duration
- **Alerting**: Condition has been true for longer than the `for` duration
- **NoData**: Query returned no data
- **Error**: Query execution failed

### Alert Lifecycle
1. **Evaluation**: Grafana runs queries according to the rule group interval
2. **Condition Check**: Results are compared against thresholds
3. **State Transition**: Alert state changes based on results
4. **Notification**: If state is "Alerting", notifications are sent according to policies
5. **Resolution**: When condition becomes false, alert returns to "Normal"

### Best Practices for Alert Configuration

#### Choosing Thresholds
- **Start Conservative**: Begin with loose thresholds and tighten based on data
- **Consider Baselines**: Use historical data to understand normal patterns
- **Account for Seasonality**: Some services have predictable traffic patterns
- **Separate Critical vs Warning**: Use different thresholds for different severity levels

#### Setting Evaluation Intervals
- **Balance Responsiveness vs Load**: More frequent evaluation catches issues faster but uses more resources
- **Match Your SLAs**: If you have a 5-minute SLA, don't evaluate every 30 seconds
- **Consider Data Granularity**: Don't evaluate faster than your metric collection interval

#### Structuring Notification Policies
- **Route by Severity**: Critical alerts should wake people up; warnings can wait
- **Group Related Alerts**: Avoid spam by grouping related alerts
- **Escalation Paths**: Route to on-call rotation, then to managers, then to executives
- **Time-Based Routing**: Different contacts for business hours vs off-hours

## Further Reading and Resources

### Grafana Documentation
- [Grafana Unified Alerting](https://grafana.com/docs/grafana/latest/alerting/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Alert Notification Templates](https://grafana.com/docs/grafana/latest/alerting/manage-notifications/template-notifications/)

### Best Practices
- [Site Reliability Engineering Book](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Synthetic Monitoring Best Practices](https://grafana.com/blog/2022/03/10/best-practices-for-alerting-on-synthetic-monitoring-metrics-in-grafana-cloud/)
- [Alert Fatigue Prevention](https://grafana.com/blog/2024/05/14/grafana-alerting-new-tools-to-resolve-incidents-faster-and-avoid-alert-fatigue/)

## Next Steps

With your alerting system in place, consider:

1. **Creating Dashboards**: Visualize your synthetic monitoring data
2. **Setting Up SLOs**: Define and track Service Level Objectives
3. **Implementing Runbooks**: Document response procedures for each alert
4. **Training Your Team**: Ensure everyone understands the alerts and responses
5. **Regular Reviews**: Periodically review and tune your alerts based on experience
