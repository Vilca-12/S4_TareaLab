# Empaquetado del codigo
data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda-crop"
  output_path = "${path.module}/crop_function.zip"
}

resource "aws_lambda_function" "crop" {
  function_name    = "crop-lambda-${var.environment}"
  role             = aws_iam_role.lambda_common_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = 512
  timeout          = 60
  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_vpc.main.default_security_group_id]
  }

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = "processed/"
    }
  }
}

# TRIGGER: Conectar SQS con Lambda 
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_queue.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5 # Para que procese hasta 5 imagenes a la vez
}