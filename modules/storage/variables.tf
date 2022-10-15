variable "environment_name" {
  description = "Name of the environment. e.g. dev, qa, stage, prod"
  default     = "dev"
  type        = string
}

variable "additional_tags" {
  default = {
    Component = "storage"
    Scope     = "solution"
    Project   = "frutal"
  }
  description = "Additional resource tags"
  type        = map(string)
}

variable "fruits_table" {
  type    = string
  default = "fruits"
}

variable "audit_fruits_table" {
  type    = string
  default = "audit_fruits"
}