# TODO: Set version for passwords
resource "aws_secretsmanager_secret" "wordpress_rds_admin" {
  name = "wordpress-rds-admin"
}

resource "aws_secretsmanager_secret_version" "wordpress_rds_admin" {
  secret_id     = aws_secretsmanager_secret.wordpress_rds_admin.id
  secret_string = 
}

resource "aws_secretsmanager_secret" "wordpress_rds_password" {
  name = "wordpress-rds-password"
}

resource "aws_secretsmanager_secret_version" "wordpress_rds_password" {
  secret_id     = aws_secretsmanager_secret.wordpress_rds_password.id
  secret_string = 
}

resource "aws_secretsmanager_secret" "wordpress_rds_schema" {
  name = "wordpress-rds-schema"
}

resource "aws_secretsmanager_secret_version" "wordpress_rds_schema" {
  secret_id     = aws_secretsmanager_secret.wordpress_rds_password.id
  secret_string = 
}
