data "grafana_synthetic_monitoring_probes" "main" {}

resource "grafana_synthetic_monitoring_check" "Synthetics_BrowserCheck_login" {
  job     = "Synthetics:BrowserCheck"
  target  = "login"
  enabled = true
  probes  = [data.grafana_synthetic_monitoring_probes.main.probes.London]
  labels = {
    check_type = "browser"
  }
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../../scripts/browser.js")
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "grafana_synthetic_monitoring_check" "Synthetics_HttpCheck_http" {
  job     = "Synthetics:HttpCheck"
  target  = "http"
  enabled = true
  probes  = [data.grafana_synthetic_monitoring_probes.main.probes.Frankfurt, ]
  labels = {
    check_type = "http"
  }
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../../scripts/http.js")
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}
