resource "aws_route53_health_check" "burendo_website_health_check" {
  provider          = aws.northvirginia
  failure_threshold = "5"
  fqdn              = "burendo.com"
  port              = 443
  request_interval  = "30"
  resource_path     = "/"
  search_string     = "Welcome to Burendo"
  type              = "HTTPS_STR_MATCH"
}
