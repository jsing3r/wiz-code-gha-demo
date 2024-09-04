variable "region" {
  type        = string
  description = "The region to create instrastructure in"
  default     = "us-east-2" 
}

variable "sensor_pullkey_username" {
  description = "Username for the sensor image pull secret"
  type        = string
  sensitive   = true
  default = "wizio-repo-b1af0ff4-f15b-46f0-aa77-d928f254babe"
}

variable "sensor_pullkey_password" {
  description = "Password for the sensor image pull secret"
  type        = string
  sensitive   = true
  default = "1mKRv3oL/kIMWl+ygFJBWvpc6ch50owxKS9satjfZd+ACRAkz79n" 
}

variable "wiz_service_account_id" {
  description = "Wiz service account ID"
  type        = string
  sensitive   = true
  default = "wgxq75hrlndpbktx3eupevf2xyrh6txpwy2v4av23h3vnnrfszhgm"
}

variable "wiz_service_account_token" {
  description = "Wiz service account token"
  type        = string
  sensitive   = true
  default = "3wPUVxQcjsA1bzofeljxvBRZShVm7WBWoRwt9GrBR9qXpokY1gu2JAMR4wVW98Xf"
}
