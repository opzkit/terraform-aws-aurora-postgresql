locals {
  major_version = regex("(0|(?:[1-9]\\d*))(?:\\.(0|(?:[1-9]\\d*))(?:\\.(0|(?:[1-9]\\d*)))?(?:\\-([\\w][\\w\\.\\-_]*))?)?", var.postgresql_version)[0]
}
resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow-postgresql-${var.identifier}"
  vpc_id      = var.vpc.id
  description = "allow traffic to postgres"

  egress {
    description = "allow outgoing traffic from postgres"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc.cidr_block]
  }
  # This is probably secure enough - can be removed and setup externally if needed...
  ingress {
    description = "allow traffic to postgres on port 5432"
    from_port   = 5432
    protocol    = "TCP"
    to_port     = 5432
    cidr_blocks = [var.vpc.cidr_block]
  }
}

resource "aws_rds_cluster" "default" {
  #checkov:skip=CKV2_AWS_8: "Ensure that RDS clusters has backup plan of AWS Backup"
  #checkov:skip=CKV_AWS_139: Deletion protection enabled by variable
  deletion_protection = var.deletion_protection
  #checkov:skip=CKV_AWS_162: IAM authentication disabled
  iam_database_authentication_enabled = false
  #checkov:skip=CKV2_AWS_27: "Ensure Postgres RDS as aws_rds_cluster has Query Logging enabled"
  #checkov:skip=CKV_AWS_324: Log capture enabled by variable
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports ? ["postgresql", "upgrade"] : []
  cluster_identifier              = var.identifier
  engine                          = "aurora-postgresql"
  engine_version                  = var.postgresql_version
  engine_mode                     = "provisioned"
  availability_zones              = var.zones
  database_name                   = var.db_name
  master_username                 = var.master_username
  master_password                 = local.password
  backup_retention_period         = 14
  preferred_backup_window         = "03:00-05:00"
  db_subnet_group_name            = aws_db_subnet_group.default.name
  vpc_security_group_ids = [
    aws_security_group.allow_postgres.id
  ]
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.identifier}-final"
  storage_encrypted               = true
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_parameters.name
  kms_key_id                      = var.kms_key_arn
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  apply_immediately               = var.apply_immediately
  copy_tags_to_snapshot           = true
}

resource "aws_rds_cluster_instance" "writer" {
  #checkov:skip=CKV_AWS_118: Monitoring enabled by variable
  cluster_identifier                    = aws_rds_cluster.default.cluster_identifier
  identifier                            = "${var.identifier}-writer"
  instance_class                        = var.writer_instance_type
  engine                                = aws_rds_cluster.default.engine
  engine_version                        = aws_rds_cluster.default.engine_version
  monitoring_interval                   = var.enhanced_monitoring ? 60 : 0
  monitoring_role_arn                   = var.enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  performance_insights_kms_key_id       = var.kms_key_arn == "" ? null : var.kms_key_arn
  performance_insights_enabled          = true
  performance_insights_retention_period = var.performance_insights_retention_period
  ca_cert_identifier                    = var.ca_cert_identifier
  auto_minor_version_upgrade            = true
}

resource "aws_rds_cluster_parameter_group" "cluster_parameters" {
  family = "aurora-postgresql${local.major_version}"
  name   = "${var.identifier}-cluster-parameters-${local.major_version}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
