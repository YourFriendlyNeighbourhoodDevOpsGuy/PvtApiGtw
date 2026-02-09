resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  runtime       = "python3.11"
  handler       = "index.handler"
  filename      = var.filename
}