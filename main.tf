data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/arca_lambda.zip"
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for ARCA notifications"
  type        = string
  sensitive   = true
}

resource "aws_lambda_function" "arca_logic" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ARCA_Root_Cause_Analyzer"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.arca_logic.function_name
  principal     = "logs.us-east-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.nginx_logs.arn}:*"
}
