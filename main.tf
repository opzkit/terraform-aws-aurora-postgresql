resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

resource "aws_security_group" "allow_postgres" {
  vpc_id = var.vpc.id
  name   = "allow-postgresql-${var.identifier}"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = [var.vpc.cidr_block]
  }
  # This is probably secure enough - can be removed and setup externally if needed...
  ingress {
    from_port   = 5432
    protocol    = "TCP"
    to_port     = 5432
    cidr_blocks = [var.vpc.cidr_block]
  }
}

resource "aws_rds_cluster" "default" {
  cluster_identifier      = var.identifier
  engine                  = "aurora-postgresql"
  engine_version          = var.postgresql_version
  engine_mode             = "provisioned"
  availability_zones      = var.zones
  database_name           = var.db_name
  master_username         = var.master_username
  master_password         = local.password
  backup_retention_period = 14
  preferred_backup_window = "03:00-05:00"
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids = [
  aws_security_group.allow_postgres.id]
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = "${var.identifier}-final"
  storage_encrypted               = true
}

resource "aws_rds_cluster_instance" "writer" {
  cluster_identifier  = aws_rds_cluster.default.cluster_identifier
  identifier          = "${var.identifier}-writer"
  instance_class      = var.writer_instance_type
  engine              = aws_rds_cluster.default.engine
  engine_version      = aws_rds_cluster.default.engine_version
  monitoring_interval = var.enhanced_monitoring ? 60 : 0
  monitoring_role_arn = var.enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}
