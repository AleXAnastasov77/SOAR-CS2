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
resource "aws_iam_policy" "lambda_policy" {
  name        = "soar_lambda_policy"
  description = "Access to SNS and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:eu-central-1:057827529833:secret:soar-*",
        Effect   = "Allow"
      },
      {
        Action   = ["sns:Publish"],
        Resource = aws_sns_topic.sns_soar.arn,
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
        aws_lambda_function.notify.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "stepfunction_invoke_attach" {
  role       = aws_iam_role.stepfunction_role.name
  policy_arn = aws_iam_policy.stepfunction_invoke.arn
}