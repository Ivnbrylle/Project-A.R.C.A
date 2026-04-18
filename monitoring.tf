resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/aws/ec2/nginx-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_subscription_filter" "arca_filter" {
  name            = "ARCA_Nginx_Error_Filter"
  log_group_name  = aws_cloudwatch_log_group.nginx_logs.name
  filter_pattern  = ""  # <--- Change this to empty quotes
  destination_arn = aws_lambda_function.arca_logic.arn
  depends_on      = [aws_lambda_permission.allow_cloudwatch]
}