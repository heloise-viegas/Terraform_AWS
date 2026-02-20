# resource "aws_s3_bucket" "backend-s3" {
#   bucket = "tf-hv-state-bucket"

#   tags = {
#     Name = "tf-hv-state-bucket"
#   }
# }

# resource "aws_dynamodb_table" "backend-db" {
#   name         = "tf-lock-dynamodb-table"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "UserId"
#   tags = {
#     Name = "tf-lock-dynamodb-table"
#   }

#   attribute {
#     name = "UserId"
#     type = "S"
#   }
# }

terraform {
  backend "s3" {
    bucket         = "tf-hv-state-bucket"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tf-lock-dynamodb-table"
  }
}
