variable "identifier" {
  type        = string
  description = "Cluster identifier"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "writer_instance_type" {
  type        = string
  description = "Instance type of writers"
  default     = "db.t3.medium"
}

variable "postgresql_version" {
  type        = string
  description = "The postgresql version to use"
  default     = "13.3"
}

variable "zones" {
  type        = list(string)
  description = "Availability zones"
}

variable "master_username" {
  type        = string
  description = "Username for master user"
}

variable "vpc" {
  type        = object({ id : string, cidr_block : string })
  description = "The VPC to create the cluster in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids where cluster should be located"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Store final snapshot or not when destroying database"
}

variable "cluster_parameters" {
  type        = map(string)
  default     = {}
  description = "cluster parameter group overrides"
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key to use for encryption, pass null to use AWS default KMS encryption"
}

variable "enhanced_monitoring" {
  type        = bool
  default     = false
  description = "Enable enhanced monitor on the instance"
}

variable "performance_insights_retention_period" {
  type        = number
  default     = 7
  description = "Performance insights retention period in days, 7 days is free of charge. Read more here: https://aws.amazon.com/rds/performance-insights/pricing"
}

variable "apply_immediately" {
  type        = bool
  default     = false
  description = "Apply changes immediately instead of next service window"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "Enable delete protection"
}

variable "enabled_cloudwatch_logs_exports" {
  type        = bool
  default     = false
  description = "Enable log exports to cloudwatch"
}


variable "allow_major_version_upgrade" {
  type        = bool
  default     = false
  description = "Allow upgrades of major as well as minor version"
}

variable "ca_cert_identifier" {
  type        = string
  default     = null
  description = "The CA cert identifier to use"
}
