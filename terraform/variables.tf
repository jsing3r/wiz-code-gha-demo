variable "region" {
  type        = string
  description = "The region to create instrastructure in"
  default     = " "
}

variable "sensor_pullkey_username" {
  description = "Username for the sensor image pull secret"
  type        = string
  sensitive   = true
  default = " "
}

variable "sensor_pullkey_password" {
  description = "Password for the sensor image pull secret"
  type        = string
  sensitive   = true
  default = " "
}

variable "wiz_service_account_id" {
  description = "Wiz service account ID"
  type        = string
  sensitive   = true
  default = " "
}

variable "wiz_service_account_token" {
  description = "Wiz service account token"
  type        = string
  sensitive   = true
  default = " "
}