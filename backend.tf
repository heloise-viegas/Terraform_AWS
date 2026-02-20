resource "aws_s3_bucket" "backend-s3" {
  bucket = "tf-stste-magmt-bucket"

  tags = {
    Name = "tf-stste-magmt-bucket"
  }
}

resource "aws_dynamodb_table" "backend-db" {
  name         = "tf-state-locking-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserId"
  tags = {
    Name = "tf-state-locking-table"
  }

  attribute {
    name = "UserId"
    type = "S"
  }
}