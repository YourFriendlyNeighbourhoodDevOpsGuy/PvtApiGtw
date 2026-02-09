terraform {
  backend "s3" {
  }
}

module "iam" {
  source    = "../modules/iam"
  role_name = "private-api-lambda-role"
}

module "lambda" {
  source        = "../modules/lambda"
  function_name = "private-api-handler"
  role_arn      = module.iam.role_arn
  filename      = "lambda.zip"
}

module "private_api" {
  source               = "../modules/apigateway-private"
  api_name             = "private-rest-api"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  vpce_id              = var.vpce_id
}