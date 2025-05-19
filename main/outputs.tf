output "synthetic_monitoring_check_id" {
  description = "The ID of the created synthetic monitoring check."
  value       = grafana_synthetic_monitoring_check.Schiphol_BrowserCheck_homepage.id
}
