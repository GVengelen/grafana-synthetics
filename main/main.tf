resource "grafana_synthetic_monitoring_check" "Schiphol_BrowserCheck_homepage" {
  job     = "Schiphol:BrowserCheck"
  target  = "homepage"
  enabled = true
  probes  = [1]
  labels  = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/schiphol_homepage.js")
    }
  }
}
resource "grafana_synthetic_monitoring_check" "Schiphol_BrowserCheck_homepage2" {
  job     = "Schiphol:BrowserCheck2"
  target  = "homepage"
  enabled = true
  probes  = [1]
  labels  = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../scripts/schiphol_homepage.js")
    }
  }
}