provider "aws" {
  region = "eu-central-1"
}

locals {
  name = "terraform-aws-lambda-test"
}

module "lambda_function" {
  source         = "../../"
  create_package = false
  function_name  = local.name
  handler        = "index.handler"
  source_path    = "./code/test/index.js"

  policy_statements = {
    dynamodb = {
      actions   = ["dynamodb:GetItem"],
      resources = ["*"]

    },
  }

  allowed_triggers = {
    APIGateway = {
      service = "apigateway"
      arn     = aws_apigatewayv2_api.main.execution_arn
    }
  }
}

resource "aws_apigatewayv2_api" "main" {
  name          = local.name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "main"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "test" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /test"
  target    = "integrations/${aws_apigatewayv2_integration.test.id}"
}

resource "aws_apigatewayv2_integration" "test" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_uri    = module.lambda_function.function_invoke_arn
  integration_method = "POST"
}


output "url" {
  value = aws_apigatewayv2_stage.main.invoke_url
}
