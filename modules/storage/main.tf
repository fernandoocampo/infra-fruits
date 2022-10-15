resource "aws_dynamodb_table" "fruits" {
  name           = var.fruits_table
  read_capacity  = "5"
  write_capacity = "5"
  attribute {
    name = "id"
    type = "S"
  }
  hash_key = "id"

  tags = merge(
    var.additional_tags,
    {
      Table   = var.fruits_table
      Service = "fruits"
    }
  )
}

resource "aws_dynamodb_table" "audit_fruits" {
  name           = var.audit_fruits_table
  read_capacity  = "5"
  write_capacity = "5"
  attribute {
    name = "id"
    type = "S"
  }
  hash_key = "id"

  tags = merge(
    var.additional_tags,
    {
      Table   = var.audit_fruits_table
      Service = "gofunction"
    }
  )
}