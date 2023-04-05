resource "aws_s3_bucket" "website_assets" {
  bucket = "${local.project_name}-assets-${local.env}"

  tags = {
    Name        = "${local.project_name}-assets-${local.env}"
    Environment = "${local.env}"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
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
