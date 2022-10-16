variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Name of the environment. e.g. dev, qa, stage, prod"
  default     = "dev"
}

variable "fruits_topic_name" {
  description = "Name of the fruits topic"
  default     = "fruits"
  type        = string
}