resource "aws_kms_key" "website_s3_bucket_key" {
  description             = "This key is used to encrypt website assets on S3"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "website_s3_bucket_key" {
  name          = "alias/burendo-website-infrastructure/website-asset-bucket-key"
  target_key_id = aws_kms_key.website_s3_bucket_key.key_id
}
