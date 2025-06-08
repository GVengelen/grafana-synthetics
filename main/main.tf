resource "grafana_synthetic_monitoring_check" "Synthetics_BrowserCheck_homepage" {
  job       = "Synthetics:BrowserCheck"
  target    = "homepage"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.London]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/script.js")
    }
  }
}
resource "grafana_synthetic_monitoring_check" "Synthetics_BrowserCheck_homepage2" {
  job       = "Synthetics:BrowserCheck2"
  target    = "homepage"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.Frankfurt,]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/script.js")
    }
  }
}