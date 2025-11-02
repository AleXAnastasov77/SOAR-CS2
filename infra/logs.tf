resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/soar_api-dev"
  retention_in_days = 7
}