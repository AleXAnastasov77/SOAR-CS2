# Simple Notification Service (For alerts)
resource "aws_sns_topic" "sns_soar" {
  name              = "soar_notifications"
  kms_master_key_id = "alias/aws/sns"
}

# Step function
# resource "aws_lambda_function" "check_misp" {
#   function_name = "check_misp"
#   handler       = "check_misp.lambda_handler"
#   runtime       = "python3.12"
#   role          = aws_iam_role.lambda_role.arn
#   filename      = "${path.module}/lambdas/check_misp.zip"
# }

# resource "aws_lambda_function" "create_case" {
#   function_name = "create_case"
#   handler       = "create_case.lambda_handler"
#   runtime       = "python3.12"
#   role          = aws_iam_role.lambda_role.arn
#   filename      = "${path.module}/lambdas/create_case.zip"
# }

# resource "aws_lambda_function" "block_ip" {
#   function_name = "block_ip"
#   handler       = "block_ip.lambda_handler"
#   runtime       = "python3.12"
#   role          = aws_iam_role.lambda_role.arn
#   filename      = "${path.module}/lambdas/block_ip.zip"
# }

# resource "aws_lambda_function" "notify" {
#   function_name = "notify"
#   handler       = "notify.lambda_handler"
#   runtime       = "python3.12"
#   role          = aws_iam_role.lambda_role.arn
#   filename      = "${path.module}/lambdas/notify.zip"
# }
resource "aws_sfn_state_machine" "soar_workflow" {
  name       = "soar-stepfunction"
  role_arn   = aws_iam_role.stepfunction_role.arn
  definition = file("${path.module}/step_function/definition.json")
}

# API Gateway
resource "aws_apigatewayv2_api" "soar_api" {
  name          = "soar_api"
  protocol_type = "HTTP"
}
# API Gateway attachment to step function

resource "aws_apigatewayv2_integration" "stepfunction_integration" {
  api_id             = aws_apigatewayv2_api.soar_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_sfn_state_machine.soar_workflow.arn
  integration_method = "POST"
}