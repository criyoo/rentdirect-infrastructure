output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

output "media_bucket_arn" {
  value = aws_s3_bucket.media.arn
}

output "media_bucket_domain_name" {
  value = aws_s3_bucket.media.bucket_regional_domain_name
}

output "frontend_bucket_id" {
  value = aws_s3_bucket.frontend.id
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_regional_domain_name" {
  value = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "api_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "app_secure_parameter_arns" {
  value = {
    for key, parameter in aws_ssm_parameter.app_secure :
    key => parameter.arn
  }
}
