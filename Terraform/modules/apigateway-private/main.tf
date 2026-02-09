data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name

  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

resource "aws_api_gateway_rest_api_policy" "private_policy" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "execute-api:/*"

        Condition = {
          StringEquals = {
            "aws:SourceVpce" = var.vpce_id
          }
        }
      }
    ]
  })
}


resource "aws_api_gateway_resource" "invoke" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "invoke"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.invoke.id
  http_method   = "POST"
  authorization = "IAM"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.invoke.id
  http_method = aws_api_gateway_method.post.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowPrivateApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_resource.invoke.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.lambda.id,
      aws_api_gateway_rest_api_policy.private_policy.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}


resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}
