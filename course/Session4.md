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

### Step 2: Synthetic Check — Failing (success rate below 100%)

This alert detects when a synthetic check's overall success rate drops to less than 100% for a sustained period. The rule queries the pre-computed `probe_check_success_rate` and triggers when the last value is below `1` in other words, not 100% succesful.

Add the following rule to your `alerts.tf` file (name: `SyntheticCheckFailing`):

```terraform
  rule {
    name      = "SyntheticCheckFailing"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 120
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          avg by(instance, job) (probe_check_success_rate)
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
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} has a success rate below 100%."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "critical"
    }
  }
```

Key points:

- **Metric**: `probe_check_success_rate` (pre-computed success rate)
- **Window**: 120s (relative time range)
- **Condition**: last value < 1 (any drop below 100%)
- **For**: 2 minutes (reduces false positives from brief blips)
- **Severity**: `critical`

### Step 3: Synthetic Check — Degraded (success rate below 90%)

A separate, lower-severity alert detects when a check's success rate falls below 90% (but not fully failing). This helps catch degradation before a total outage.

Add the following rule to your `alerts.tf` file (name: `SyntheticCheckDegraded`):

```terraform
  rule {
    name      = "SyntheticCheckDegraded"
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
          avg by(instance, job) (probe_check_success_rate)
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
              params = [0.9]
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
      summary     = "synthetic check degraded"
      description = "check job {{ $labels.job }} instance {{ $labels.instance }} has a success rate below 90%."
    }

    labels = {
      namespace = "synthetic_monitoring"
      severity  = "warning"
    }
  }
```

Key differences vs the failing alert:

- **Threshold**: 0.9 (90%) instead of 1.0 (100%)
- **Window**: 300s and `for` 5 minutes to reduce noise
- **Severity**: `warning` to indicate degradation rather than full outage

### Step 4: High Latency Alert

Performance matters as much as availability. Let's add an alert for high latency on non-browser checks:

```terraform
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
          avg_over_time(probe_duration_seconds{job!~"Browser:.*"}[5m])
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
```

Key points about this alert:

- The query uses `avg_over_time(probe_duration_seconds{job!~"Browser:.*"}[5m])` to calculate the average probe duration over 5 minutes
- The filter `job!~"Browser:.*""` excludes browser checks, since those naturally take longer to execute and would create false positives
- The threshold is 5 seconds, if the average latency exceeds this, the alert fires
- It is labeled `severity = "warning"` since high latency is not as urgent as a complete failure

### Step 5: Multiple Checks Failing Simultaneously

When multiple checks fail at the same time, it often indicates a broader infrastructure issue rather than a single service problem. Let's add an alert for this:

```terraform
  rule {
    name      = "MultipleSyntheticChecksFailing"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 180
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr          = <<-EOT
          count(probe_check_success_rate < 1)
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
              params = [2]
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
```

This alert takes a different approach from the previous ones:

- Instead of looking at individual checks, `sum(probe_success == 0)` counts the **total number of checks** where `probe_success` equals 0 (i.e., the check is currently failing)
- The threshold is **greater than 3** — meaning more than 3 checks must be failing simultaneously
- The `for` duration is **3 minutes**, a balance between reacting quickly and avoiding false positives from brief network blips
- It's marked `severity = "critical"` because multiple simultaneous failures likely indicate a systemic issue

### Step 6: HTTP 5xx Error Detection

Server-side errors (HTTP 500+) indicate application-level problems. Let's add an alert that catches these:

```terraform
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
```

This alert specifically targets HTTP server errors:

- `max_over_time(probe_http_status_code[5m])` takes the **maximum** HTTP status code observed over the last 5 minutes — using `max` ensures we don't miss intermittent 5xx errors that average out
- The condition `gte 500` triggers on any HTTP status code of 500 or higher (500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable, etc.)
- The `for` duration is only **1 minute** — 5xx errors are almost always serious and should be alerted on quickly
- It is `severity = "critical"` since server errors directly impact users

> **Note**: Don't forget to close the `grafana_rule_group` block with `}` after this last rule. All five rules should be nested inside the same `resource "grafana_rule_group"` block.

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
# Step 8: Contact point for synthetic monitoring alerts
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
```

**Important**: Replace `<your email address>` with your actual email address.

The message template uses Grafana's template language to include:

- Alert name
- Summary and description from annotations
- All labels for context

### Step 9: Creating Notification Policies

Contact points define _how_ to send alerts, but notification policies define _when_ and _to whom_. Let's set up routing:

```terraform
# Step 9: Create a notification policy for these alerts
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

Before we can deploy our new alerts, we'll need to update the rights of our Service Account. We'll be creating `folders` and `alerts`, so add those roles and click update in Grafana cloud.

You can find this option under `/org/serviceaccounts`, on this page:

1. Look for `synthetic-acces-policy`
2. Add `Alerting Admin` role
3. Add `Folder Admin` role
4. In the select window click `update`.

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
- **Separate Critical vs non-criticals**: Use different thresholds for different severities

#### Setting Evaluation Intervals

- **Balance Responsiveness vs Load**: More frequent evaluation catches issues faster but uses more resources
- **Match Your SLAs**: If you have a 5-minute SLA, don't evaluate every 30 seconds
- **Consider Data Granularity**: Don't evaluate faster than your metric collection interval

#### Structuring Notification Policies

- **Route by Severity**: Critical alerts should wake people up; warnings can wait
- **Group Related Alerts**: Avoid spam by grouping related alerts
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
