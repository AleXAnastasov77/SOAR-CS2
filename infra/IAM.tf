# IAM for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "soar_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
# IAM for SF
resource "aws_iam_role" "stepfunction_role" {
  name = "soar_stepfunction_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_fullaccess" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
# IAM Policy for access to SNS and Secrets Manager
# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "lambda_policy" {
  name        = "soar_lambda_policy"
  description = "Access to SNS and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:eu-central-1:057827529833:secret:soar-hNwDoe",
        Effect   = "Allow"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.sns_cmk.arn
      },
      {
        Action   = ["sns:Publish"],
        Resource = aws_sns_topic.sns_soar.arn,
        Effect   = "Allow"
      },
      {
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
# IAM Policy for step function
resource "aws_iam_policy" "stepfunction_invoke" {
  name = "soar_stepfunction_invoke"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["lambda:InvokeFunction"],
      Resource = [
        aws_lambda_function.check_misp.arn,
        aws_lambda_function.create_case.arn,
        aws_lambda_function.block_ip.arn,
        aws_lambda_function.notify.arn,
        aws_lambda_function.send_to_elastic.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "stepfunction_invoke_attach" {
  role       = aws_iam_role.stepfunction_role.name
  policy_arn = aws_iam_policy.stepfunction_invoke.arn
}

# IAM FOR API GATEWAY
resource "aws_iam_role" "api_gateway_stepfn_role" {
  name = "api-gateway-stepfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_stepfn_policy" {
  role = aws_iam_role.api_gateway_stepfn_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["states:StartExecution"],
        Resource = aws_sfn_state_machine.soar_workflow.arn
      }
    ]
  })
}
