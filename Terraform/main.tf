terraform {
  backend "s3" {
  }
}

locals {
  effective_vpce_id = var.create_vpc_endpoint
    ? aws_vpc_endpoint.execute_api[0].id
    : var.vpce_id
}

module "iam" {
  source        = "./modules/iam"
  role_name    = "private-api-lambda-role"
  secret_arn   = var.secret_arn
  s3_bucket_arn = var.s3_bucket_arn
}

module "lambda" {
  source        = "./modules/lambda"
  function_name = "private-api-handler"
  role_arn      = module.iam.role_arn
  filename      = "lambda.zip"
}

module "private_api" {
  source               = "./modules/apigateway-private"
  api_name             = "private-rest-api"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  vpce_id              = local.effective_vpce_id
}

############################################################
# OPTIONAL: VPC Interface Endpoint for Private API Gateway
############################################################

resource "aws_vpc_endpoint" "execute_api" {
  count = var.create_vpc_endpoint ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.vpce_security_group_ids

  private_dns_enabled = true

  tags = {
    Name = "execute-api-vpce"
  }
}
