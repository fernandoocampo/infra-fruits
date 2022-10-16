output "sns_id" {
  value       = aws_sns_topic.fruits.id
  description = "SNS Topic Id"
}

output "sns_arn" {
  value       = aws_sns_topic.fruits.arn
  description = "SNS Topic Arn"
}

output "sqs_arn" {
  description = "SQS Arn"
  value       = aws_sqs_queue.audit_fruits.arn
}

output "sqs_url" {
  description = "SQS Url"
  value       = aws_sqs_queue.audit_fruits.id
}