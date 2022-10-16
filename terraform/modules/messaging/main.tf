resource "aws_sns_topic" "fruits" {
  name            = var.fruits_topic_name
  fifo_topic      = false
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  tags = merge(
    var.additional_tags,
    {
      Topic = var.fruits_topic_name
    }
  )
}

resource "aws_sqs_queue" "audit_fruits" {
  name       = var.audit_fruits_queue_name
  fifo_queue = false

  tags = merge(
    var.additional_tags,
    {
      Queue   = var.audit_fruits_queue_name
      Service = "audit"
    }
  )
}

resource "aws_sns_topic_subscription" "fruits_sqs_audit" {
  topic_arn = aws_sns_topic.fruits.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.audit_fruits.arn
}