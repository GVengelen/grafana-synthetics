variable "grafana_service_token" {
  description = "Grafana service token"
  type        = string
  sensitive   = true
}

variable "sm_access_token" {
  description = "Synthetic Monitoring access token"
  type        = string
  sensitive   = true
}

variable "alert_notification_email" {
  description = "Email address for synthetic monitoring alerts"
  type        = string
  default     = "platform-team@company.com"
}

variable "reachability_threshold" {
  description = "Reachability threshold for alerts (0-1 range)"
  type        = number
  default     = 0.9
}

variable "latency_threshold_seconds" {
  description = "Latency threshold in seconds for alerts"
  type        = number
  default     = 1.0
}

variable "error_rate_threshold" {
  description = "Error rate threshold for alerts (0-1 range)"
  type        = number
  default     = 0.1
}

variable "error_rate_by_probe_threshold" {
  description = "Error rate threshold by probe for alerts (0-1 range)"
  type        = number
  default     = 0.5
}
