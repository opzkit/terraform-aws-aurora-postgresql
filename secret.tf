resource "aws_secretsmanager_secret" "aurora_secret" {
  #checkov:skip=CKV2_AWS_57: "Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "rds/postgres/${var.identifier}"
}

resource "aws_secretsmanager_secret_version" "aurora_secret_value" {
  secret_id     = aws_secretsmanager_secret.aurora_secret.id
  secret_string = jsonencode(local.secret_value)
}

locals {
  secret_value = {
    DB_USERNAME  = var.master_username
    DB_PASSWORD  = local.password
    DB_NAME      = aws_rds_cluster.default.cluster_identifier
    DB_PORT      = tostring(aws_rds_cluster.default.port)
    DB_HOST      = aws_rds_cluster.default.endpoint
    POSTGRES_URL = "postgres://${var.master_username}:${local.password}@${aws_rds_cluster.default.endpoint}:${aws_rds_cluster.default.port}/${aws_rds_cluster.default.cluster_identifier}?sslmode=${var.ssl_mode}"
  }
  password = random_password.password.result
}

resource "random_password" "password" {
  length           = 32
  special          = false
  lower            = true
  upper            = true
  numeric          = true
  override_special = ""
  min_special      = 0
  min_lower        = 5
  min_upper        = 5
  min_numeric      = 5
  lifecycle {
    ignore_changes = all
  }
}
