resource "aws_s3_bucket" "cloudtictactoe_avatars" {
  bucket = "cloudtictactoe-avatars"
}

resource "aws_s3_bucket_public_access_block" "cloudtictactoe_avatars_pab" {
  bucket = aws_s3_bucket.cloudtictactoe_avatars.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.cloudtictactoe_avatars.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicRead",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : ["s3:GetObject"],
          "Resource" : [
            "${aws_s3_bucket.cloudtictactoe_avatars.arn}",
            "${aws_s3_bucket.cloudtictactoe_avatars.arn}/*"
          ]
        }
      ]
    }
  )

  depends_on = [ aws_s3_bucket_public_access_block.cloudtictactoe_avatars_pab ]
}