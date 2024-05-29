resource "aws_s3_bucket" "backup" {
  provider = aws.compute
  bucket   = var.domain-name
  
  tags = {
    Name   = var.tag-name
    BillTo = var.tag-bill-to
    Type   = var.tag-type
  }
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_s3_bucket_lifecycle_configuration" "backup" {
#   bucket = aws_s3_bucket.backup.id
#   rule {
#     id = "glacier-older-30"
#     status = "Enabled"
# 
#     noncurrent_version_transition {
#       noncurrent_days = var.backup-days-till-glacier
#       storage_class   = "GLACIER"
#     }
# 
#     noncurrent_version_expiration {
#       noncurrent_days = var.backup-days-till-expire
#     }
#   }
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}