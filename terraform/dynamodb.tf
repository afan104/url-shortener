resource "aws_dynamodb_table" "main" {
  name         = "url-shortener"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code"

  attribute {
    name = "code"
    type = "S"
  }
}

