variable "environment_name" {
  description = "Name of the environment. e.g. dev, qa, stage, prod"
  default     = "dev"
  type        = string
}

variable "additional_tags" {
  default = {
    Component = "messaging"
    Scope     = "solution"
    Project   = "frutal"
  }
  description = "Additional resource tags"
  type        = map(string)
}

variable "fruits_topic_name" {
  type    = string
  default = "fruits"
}

variable "audit_fruits_queue_name" {
  type    = string
  default = "fruits-queue"
}