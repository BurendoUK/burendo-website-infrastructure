resource "aws_cloudwatch_metric_alarm" "burendo_website_health_check_alarm" {
  provider                  = aws.northvirginia
  alarm_name                = "${local.environment}-burendo-website-health-check-alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "HealthCheckStatus"
  namespace                 = "AWS/Route53"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1"
  insufficient_data_actions = []
  ok_actions                = [data.terraform_remote_state.burendo_common_config.outputs.sns_topic_alerts_to_slack.arn]
  alarm_actions             = [data.terraform_remote_state.burendo_common_config.outputs.sns_topic_alerts_to_slack.arn]
  alarm_description         = "Send an alarm if burendo website is down in ${local.environment}"

  dimensions = {
    HealthCheckId = aws_route53_health_check.burendo_website_health_check.id
  }
}
