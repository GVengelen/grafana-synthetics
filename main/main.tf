data "grafana_synthetic_monitoring_probes" "main" {}

resource "grafana_synthetic_monitoring_check" "Synthetics_BrowserCheck_login" {
  job       = "Synthetics:BrowserCheck"
  target    = "homepage"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.London]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/browser.js")
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "grafana_synthetic_monitoring_check" "Synthetics_HttpCheck_crocodiles" {
  job       = "Synthetics:BrowserCheck2"
  target    = "homepage"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.Frankfurt,]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/http.js")
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}