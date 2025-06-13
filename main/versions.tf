terraform {
  required_version = ">= 1.0.0"

  cloud {
    organization = "Grafana_Synthetics_Workshop"

    workspaces {
      name = "grafana-synthetics-main"
    }
  }

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 2.0.0"
    }
  }
}
