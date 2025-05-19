terraform {
  required_version = ">= 1.0.0"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 2.0.0"
    }
  }
}
