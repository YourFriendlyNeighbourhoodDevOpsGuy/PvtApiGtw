output "api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  description = "Private invoke URL (accessible only via VPC endpoint)"
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/invoke"
}
