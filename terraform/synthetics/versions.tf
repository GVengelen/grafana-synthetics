terraform {
  required_version = ">= 1.1.0"

  cloud {
    organization = "mufaxx"

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