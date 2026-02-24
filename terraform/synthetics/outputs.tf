output "synthetic_browser_monitoring_check_id" {
  description = "The ID of the created synthetic monitoring check."
  value       = grafana_synthetic_monitoring_check.Synthetics_BrowserCheck_login
}
output "synthetic_http_monitoring_check_id" {
  description = "The ID of the created synthetic monitoring check."
  value       = grafana_synthetic_monitoring_check.Http_GetPizza
}
