data "external" "create_source_bundle" {
  program = ["bash", "${path.module}/make-source-bundle.sh"]
}

resource "aws_s3_bucket" "cloudtictactoe_server_bucket" {
  bucket = "cloudtictactoe-bucket-1"

  tags = {
    Name = "Cloud Tic Tac Toe S3 Bucket"
  }
}

resource "aws_s3_object" "cloudtictactoe_server_source_bundle" {
  bucket = aws_s3_bucket.cloudtictactoe_server_bucket.id
  key    = data.external.create_source_bundle.result.path
  source = data.external.create_source_bundle.result.path
  etag   = data.external.create_source_bundle.result.md5

  depends_on = [data.external.create_source_bundle]

  tags = {
    Name = "Cloud Tic Tac Toe Source Bundle"
  }
}