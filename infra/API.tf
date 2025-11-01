# === REST API ===
resource "aws_api_gateway_rest_api" "soar_api" {
  name        = "soar_api"
  description = "SOAR REST API to trigger Step Function"
}

# Add /alert endpoint
resource "aws_api_gateway_resource" "alert" {
  rest_api_id = aws_api_gateway_rest_api.soar_api.id
  parent_id   = aws_api_gateway_rest_api.soar_api.root_resource_id
  path_part   = "alert"
}

# Allow POST to /alert
resource "aws_api_gateway_method" "alert_post" {
  rest_api_id   = aws_api_gateway_rest_api.soar_api.id
  resource_id   = aws_api_gateway_resource.alert.id
  http_method   = "POST"
  authorization = "NONE"
}

# Connect API → Step Function
resource "aws_api_gateway_integration" "stepfn_integration" {
  rest_api_id             = aws_api_gateway_rest_api.soar_api.id
  resource_id             = aws_api_gateway_resource.alert.id
  http_method             = aws_api_gateway_method.alert_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:states:action/StartExecution"

  credentials = aws_iam_role.stepfunction_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "stateMachineArn": "${aws_sfn_state_machine.soar_workflow.arn}",
  "input": "$util.escapeJavaScript($input.body)"
}
EOF
  }
}


resource "aws_api_gateway_method_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.soar_api.id
  resource_id = aws_api_gateway_resource.alert.id
  http_method = aws_api_gateway_method.alert_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.soar_api.id
  resource_id = aws_api_gateway_resource.alert.id
  http_method = aws_api_gateway_method.alert_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "soar_deploy" {
  rest_api_id = aws_api_gateway_rest_api.soar_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.alert.id,
      aws_api_gateway_method.alert_post.id,
      aws_api_gateway_integration.stepfn_integration.id,
      aws_api_gateway_method_response.ok.id,
      aws_api_gateway_integration_response.ok.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.soar_api.id
  deployment_id = aws_api_gateway_deployment.soar_deploy.id
  stage_name    = "dev"
}