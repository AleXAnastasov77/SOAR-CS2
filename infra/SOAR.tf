# Customer key for the SNS
resource "aws_kms_key" "sns_cmk" {
  description = "Customer-managed key for SNS encryption"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EnableRootPermissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "AllowSNSServiceUse",
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowGitHubOIDC",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::057827529833:role/GitHubActionsPipeline"
        },
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ],
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
  filename         = "${path.module}/lambdas/check_misp.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/check_misp.zip")
}

resource "aws_lambda_function" "create_case" {
  function_name    = "create_case"
  handler          = "create_case.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambdas/create_case.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/create_case.zip")
}

resource "aws_lambda_function" "block_ip" {
  function_name    = "block_ip"
  handler          = "block_ip.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambdas/block_ip.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/block_ip.zip")
}
resource "aws_lambda_function" "send_to_elastic" {
  function_name    = "send_to_elastic"
  handler          = "send_to_elastic.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambdas/send_to_elastic.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/send_to_elastic.zip")
  environment {
    variables = {
      ES_HOST  = "http://siem.innovatech.internal:9200"
      ES_USER  = "elastic"
      ES_PASS  = var.elastic_password
      ES_INDEX = "soar-alerts"
    }
  }
}
resource "aws_lambda_function" "notify" {
  function_name    = "notify"
  handler          = "notify.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambdas/send_to_elastic.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/send_to_elastic.zip")
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

