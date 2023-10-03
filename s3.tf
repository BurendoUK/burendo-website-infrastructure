resource "aws_s3_bucket" "website_assets" {
  bucket = "${local.project_name}-assets-${local.environment}"
  lifecycle {
    ignore_changes = [bucket, tags]
  }

  tags = {
    Name        = "${local.project_name}-assets-${local.environment}"
    Environment = "${local.environment}"
  }
}

resource "aws_s3_bucket_acl" "website_assets" {
  bucket = aws_s3_bucket.website_assets.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "website_assets" {
  bucket = aws_s3_bucket.website_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_assets" {
  bucket = aws_s3_bucket.website_assets.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.website_s3_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_object" "nginx_config" {
  bucket = aws_s3_bucket.website_assets.id
  key    = "config/nginx/nginx.conf"
  source = "files/nginx.conf"

  etag = filemd5("files/nginx.conf")
}

resource "aws_s3_object" "nginx_wordpress_config" {
  bucket = aws_s3_bucket.website_assets.id
  key    = "config/nginx/wordpress.conf"
  source = "files/wordpress.conf"

  etag = filemd5("files/wordpress.conf")
}

resource "aws_s3_object" "wordpress_plugin_config" {
  bucket = aws_s3_bucket.website_assets.id
  key    = "config/wordpress/plugins.list"
  source = "files/plugins.list"

  etag = filemd5("files/plugins.list")
}
