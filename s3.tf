resource "aws_s3_bucket" "cloudtictactoe_avatars" {
  bucket = "cloudtictactoe-avatars"
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
}