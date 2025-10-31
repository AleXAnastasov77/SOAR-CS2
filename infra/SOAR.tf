# Customer key for the SNS
resource "aws_kms_key" "sns_cmk" {
  description = "Customer-managed key for SNS encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow SNS to use this key for encryption
      {
        Sid       = "AllowSNSUse"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      # Allow your Lambda to decrypt messages from SNS
      {
        Sid       = "AllowLambdaUse"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.lambda_role.arn }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}
# Simple Notification Service (For alerts)
resource "aws_sns_topic" "sns_soar" {
  name              = "soar_notifications"
  kms_master_key_id = aws_kms_key.sns_cmk.arn
}

#Step function
resource "aws_lambda_function" "check_misp" {
  function_name    = "check_misp"
  handler          = "check_misp.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.check_misp.output_path
  source_code_hash = data.archive_file.check_misp.output_base64sha256
  depends_on       = [data.archive_file.check_misp]
}

resource "aws_lambda_function" "create_case" {
  function_name    = "create_case"
  handler          = "create_case.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.create_case.output_path
  source_code_hash = data.archive_file.check_misp.output_base64sha256
  depends_on       = [data.archive_file.create_case]
}

resource "aws_lambda_function" "block_ip" {
  function_name    = "block_ip"
  handler          = "block_ip.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.block_ip.output_path
  source_code_hash = data.archive_file.check_misp.output_base64sha256
  depends_on       = [data.archive_file.block_ip]
}
resource "aws_lambda_function" "send_to_elastic" {
  function_name = "send_to_elastic"
  handler       = "send_to_elastic.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.send_to_elastic.output_path
  timeout       = 15
  depends_on    = [data.archive_file.send_to_elastic]
}
resource "aws_lambda_function" "notify" {
  function_name = "notify"
  handler       = "notify.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.notify.output_path
  depends_on    = [data.archive_file.notify]
  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.sns_soar.arn
    }
  }
}
resource "aws_sfn_state_machine" "soar_workflow" {
  name     = "soar-stepfunction"
  role_arn = aws_iam_role.stepfunction_role.arn
  definition = templatefile("${path.module}/step_function/definition.json", {
    check_misp_arn      = aws_lambda_function.check_misp.arn
    create_case_arn     = aws_lambda_function.create_case.arn
    block_ip_arn        = aws_lambda_function.block_ip.arn
    notify_arn          = aws_lambda_function.notify.arn
    send_to_elastic_arn = aws_lambda_function.send_to_elastic.arn
  })
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